`ifndef RTL_svh
  `define RTL_svh

    module spi_core (
        input  wire         PCLK,
        input  wire         PRESETn,

        // Configuration (live from regfile)
        input  wire         cfg_en,
        input  wire         cfg_mstr,
        input  wire [1:0]   cfg_mode,
        input  wire         cfg_lsb_first,
        input  wire         cfg_loopback,
        input  wire [1:0]   cfg_width,
        input  wire [15:0]  cfg_clk_div,
        input  wire [7:0]   cfg_delay,

        // SS observation: core starts only when at least one SS lane is asserted
        // low on the pins (regfile owns the final drive).
        input  wire [3:0]   ss_n_drive,

        // TX FIFO -> core
        input  wire [31:0]  tx_word,
        input  wire         tx_empty,
        output reg          tx_pop,

        // core -> RX FIFO
        output reg          rx_push_valid,
        output reg  [31:0]  rx_push_data,

        // Status
        output wire         busy,
        output reg          transfer_done_pulse,

        // SPI pins
        output reg          SCLK,
        output reg          MOSI,
        input  wire         MISO
    );

        // -------------------------------------------------------------------------
        // FSM
        // -------------------------------------------------------------------------
        typedef enum logic [1:0] {
            S_IDLE   = 2'd0,
            S_SHIFT  = 2'd1,
            S_FINISH = 2'd2,
            S_GAP    = 2'd3
        } xfer_state_e;

        xfer_state_e state;

        reg [1:0]  xfer_mode;
        reg        xfer_lsb_first;
        reg [1:0]  xfer_width;
        reg [15:0] xfer_div;

        reg [31:0] sh_tx;
        reg [31:0] sh_rx;
        reg [5:0]  bit_cnt;
        reg [16:0] sclk_cnt;
        reg [8:0]  gap_cnt;
        reg        sclk_phase;

        wire [5:0] width_bits = (xfer_width == 2'b00) ? 6'd8  :
                                (xfer_width == 2'b01) ? 6'd16 : 6'd32;

        wire cpol = xfer_mode[1];
        wire cpha = xfer_mode[0];
        wire [16:0] half_period = {1'b0, xfer_div} + 17'd1;

        assign busy = (state != S_IDLE);

        wire miso_eff = cfg_loopback ? MOSI : MISO;

        // Helper functions
        function automatic logic get_tx_bit(input logic [31:0] v,
                                            input logic [5:0]  remaining,
                                            input logic [5:0]  total_bits,
                                            input logic        lsb_first);
            if (lsb_first)
                get_tx_bit = v[total_bits - remaining];
            else
                get_tx_bit = v[remaining - 1];
        endfunction

        function automatic logic [31:0] align_rx(input logic [31:0] sh,
                                                input logic [5:0]  total_bits);
            align_rx = sh & ((total_bits == 6'd32) ? 32'hFFFF_FFFF :
                            ((32'h1 << total_bits) - 32'h1));
        endfunction

        // -------------------------------------------------------------------------
        // FSM + datapath
        // -------------------------------------------------------------------------
        always @(posedge PCLK or negedge PRESETn) begin
            if (!PRESETn) begin
                state            <= S_IDLE;
                SCLK             <= 1'b0;
                MOSI             <= 1'b0;
                sh_tx            <= 32'h0;
                sh_rx            <= 32'h0;
                bit_cnt          <= 6'h0;
                sclk_cnt         <= 17'h0;
                sclk_phase       <= 1'b0;
                gap_cnt          <= 9'h0;
                xfer_mode        <= 2'b00;
                xfer_lsb_first   <= 1'b0;
                xfer_width       <= 2'b00;
                xfer_div         <= 16'h0;
                tx_pop           <= 1'b0;
                rx_push_valid    <= 1'b0;
                rx_push_data     <= 32'h0;
                transfer_done_pulse <= 1'b0;
            end else begin
                tx_pop              <= 1'b0;
                rx_push_valid       <= 1'b0;
                transfer_done_pulse <= 1'b0;

                if (!cfg_en) begin
                    state      <= S_IDLE;
                    SCLK       <= cfg_mode[1];   // hold at CPOL idle
                    MOSI       <= 1'b0;
                    sclk_cnt   <= 17'h0;
                    sclk_phase <= 1'b0;
                    gap_cnt    <= 9'h0;
                end else begin
                    case (state)
                        // ---------------- IDLE ------------------------------------
                        S_IDLE: begin
                            SCLK <= cfg_mode[1];
                            // Start condition: TX has data, master mode, and at
                            // least one SS lane on the pins is driven low.
                            if (!tx_empty && cfg_mstr && (ss_n_drive != 4'hF)) begin
                                // Latch config for this transfer (R25)
                                xfer_mode      <= cfg_mode;
                                xfer_lsb_first <= cfg_lsb_first;
                                xfer_width     <= cfg_width;
                                xfer_div       <= cfg_clk_div;

                                sh_tx  <= tx_word;
                                tx_pop <= 1'b1;

                                bit_cnt    <= (cfg_width == 2'b00) ? 6'd8  :
                                            (cfg_width == 2'b01) ? 6'd16 : 6'd32;
                                sclk_cnt   <= 17'h0;
                                sclk_phase <= 1'b0;

                                // Present first bit immediately for CPHA=0
                                if (cfg_mode[0] == 1'b0) begin
                                    MOSI <= cfg_lsb_first ? tx_word[0]
                                                        : tx_word[
                                                            ((cfg_width==2'b00)?7:
                                                            (cfg_width==2'b01)?15:31)];
                                end
                                sh_rx <= 32'h0;
                                state <= S_SHIFT;
                                SCLK  <= cfg_mode[1];
                            end
                        end

                        // ---------------- SHIFT -----------------------------------
                        S_SHIFT: begin
                            if (sclk_cnt == half_period - 1) begin
                                sclk_cnt   <= 17'h0;
                                sclk_phase <= ~sclk_phase;
                                SCLK       <= ~SCLK;

                                begin : edge_work
                                    logic leading;
                                    logic is_sample_edge;
                                    logic is_launch_edge;
                                    leading = ~sclk_phase;
                                    is_sample_edge = (cpha == 1'b0) ? leading : ~leading;
                                    is_launch_edge = ~is_sample_edge;

                                    if (is_sample_edge) begin
                                        if (xfer_lsb_first) begin
                                            sh_rx[width_bits - bit_cnt] <= miso_eff;
                                        end else begin
                                            sh_rx[bit_cnt - 1] <= miso_eff;
                                        end

                                        if (bit_cnt == 6'd1) begin
                                            state <= S_FINISH;
                                        end
                                        bit_cnt <= bit_cnt - 6'd1;
                                    end

                                    if (is_launch_edge) begin
                                        if (bit_cnt > 6'd0) begin
                                            MOSI <= get_tx_bit(sh_tx, bit_cnt,
                                                            width_bits, xfer_lsb_first);
                                        end
                                    end

                                    // CPHA=1 first-bit-launch on very first edge
                                    if (cpha == 1'b1 && leading && bit_cnt == width_bits) begin
                                        MOSI <= get_tx_bit(sh_tx, bit_cnt,
                                                        width_bits, xfer_lsb_first);
                                    end
                                end
                            end 
                            else begin
                                sclk_cnt <= sclk_cnt + 17'h1;
                            end
                        end

                        // ---------------- FINISH ----------------------------------
                        S_FINISH: begin
                            if (sclk_cnt == half_period - 1) begin
                                sclk_cnt   <= 17'h0;
                                SCLK       <= cpol;
                                sclk_phase <= 1'b0;

                                rx_push_valid <= 1'b1;
                                rx_push_data  <= align_rx(sh_rx, width_bits);
                                transfer_done_pulse <= 1'b1;

                                if (!tx_empty && cfg_delay != 8'h0) begin
                                    gap_cnt <= {1'b0, cfg_delay};
                                    state   <= S_GAP;
                                end else begin
                                    state <= S_IDLE;
                                end
                            end else begin
                                sclk_cnt <= sclk_cnt + 17'h1;
                            end
                        end

                        // ---------------- GAP -------------------------------------
                        S_GAP: begin
                            SCLK <= cpol;
                            if (sclk_cnt == half_period - 1) begin
                                sclk_cnt <= 17'h0;
                                if (gap_cnt == 9'h1) begin
                                    state <= S_IDLE;
                                end
                                gap_cnt <= gap_cnt - 9'h1;
                            end else begin
                                sclk_cnt <= sclk_cnt + 17'h1;
                            end
                        end

                        default: state <= S_IDLE;
                    endcase
                end
            end
        end

    endmodule

    ///////////////////////////////////////////////////////////////////////////////////

    module apb_regfile (
        input  wire         PCLK,
        input  wire         PRESETn,

        // APB slave
        input  wire         PSEL,
        input  wire         PENABLE,
        input  wire         PWRITE,
        input  wire [7:0]   PADDR,
        input  wire [31:0]  PWDATA,
        // outputs
        output reg  [31:0]  PRDATA,
        output wire         PREADY,
        output wire         PSLVERR,

        // Configuration to core
        output wire         cfg_en,
        output wire         cfg_mstr,
        output wire [1:0]   cfg_mode,
        output wire         cfg_lsb_first,
        output wire         cfg_loopback,
        output wire [1:0]   cfg_width,
        output wire [15:0]  cfg_clk_div,
        output wire [7:0]   cfg_delay,

        // SS lane drive (combinational, outputs via SS_n)
        output wire [3:0]   SS_n,

        // TX FIFO interface to core
        output wire [31:0]  tx_word,        // head of TX FIFO
        output wire         tx_empty,
        input  wire         tx_pop,         // core pops one word

        // RX FIFO interface from core
        input  wire         rx_push_valid,
        input  wire [31:0]  rx_push_data,

        // Core status -> regfile
        input  wire         busy_in,
        input  wire         transfer_done_pulse,

        // Aggregate interrupt
        output wire         IRQ
    );

        // -------------------------------------------------------------------------
        // Register offsets addressed by APB PADDR (R0-R32)
        // -------------------------------------------------------------------------
        localparam [7:0] OFF_CTRL     = 8'h00;
        localparam [7:0] OFF_STATUS   = 8'h04;
        localparam [7:0] OFF_TX_DATA  = 8'h08;
        localparam [7:0] OFF_RX_DATA  = 8'h0C;
        localparam [7:0] OFF_CLK_DIV  = 8'h10;
        localparam [7:0] OFF_SS_CTRL  = 8'h14;
        localparam [7:0] OFF_INT_EN   = 8'h18;
        localparam [7:0] OFF_INT_STAT = 8'h1C;
        localparam [7:0] OFF_DELAY    = 8'h20;

        localparam integer IRQ_TX_EMPTY      = 0;
        localparam integer IRQ_RX_FULL       = 1;
        localparam integer IRQ_TX_OVF        = 2;
        localparam integer IRQ_RX_OVF        = 3;
        localparam integer IRQ_TRANSFER_DONE = 4;
        localparam integer IRQ_COUNT         = 5;

        // -------------------------------------------------------------------------
        // Configuration registers
        // -------------------------------------------------------------------------
        reg        ctrl_en;
        reg        ctrl_mstr;
        reg [1:0]  ctrl_mode;       // {CPOL, CPHA}
        reg        ctrl_lsb_first;
        reg        ctrl_loopback;
        reg [1:0]  ctrl_width;

        reg [15:0] clk_div;
        reg [3:0]  ss_en;
        reg [3:0]  ss_val;
        reg [IRQ_COUNT-1:0] int_en;
        reg [IRQ_COUNT-1:0] int_stat;
        reg [7:0]  delay_cfg;

        // -------------------------------------------------------------------------
        // APB handshake
        // -------------------------------------------------------------------------
        wire apb_access = PSEL & PENABLE;
        wire apb_write  = apb_access &  PWRITE;
        wire apb_read   = apb_access & ~PWRITE;
        assign PREADY   = 1'b1;
        assign PSLVERR  = 1'b0;

        // -------------------------------------------------------------------------
        // FIFO storage - 8 deep, 32 wide
        // -------------------------------------------------------------------------
        localparam integer FIFO_DEPTH = 8;
        localparam integer FIFO_AW    = 3;

        reg [31:0] tx_mem   [0:FIFO_DEPTH-1];
        reg [FIFO_AW:0] tx_wp, tx_rp;
        wire [FIFO_AW:0] tx_count = tx_wp - tx_rp;
        wire tx_full_w  = (tx_count == FIFO_DEPTH);
        wire tx_empty_w = (tx_count == 0);

        reg [31:0] rx_mem   [0:FIFO_DEPTH-1];
        reg [FIFO_AW:0] rx_wp, rx_rp;
        wire [FIFO_AW:0] rx_count = rx_wp - rx_rp;
        wire rx_full_w  = (rx_count == FIFO_DEPTH);
        wire rx_empty_w = (rx_count == 0);

        assign tx_empty = tx_empty_w;
        assign tx_word  = tx_mem[tx_rp[FIFO_AW-1:0]];

        // -------------------------------------------------------------------------
        // Combinational APB read data
        // -------------------------------------------------------------------------
        wire [31:0] status_word = {
            25'b0,
            int_stat[IRQ_RX_OVF],     // [6] RX_OVF
            int_stat[IRQ_TX_OVF],     // [5] TX_OVF
            rx_empty_w,               // [4] RX_EMPTY (reset = 1)
            rx_full_w,                // [3] RX_FULL
            tx_empty_w,               // [2] TX_EMPTY (reset = 1)
            tx_full_w,                // [1] TX_FULL
            busy_in                   // [0] BUSY
        };

        wire [31:0] ctrl_word = {
            24'b0,
            ctrl_width,
            ctrl_loopback,
            ctrl_lsb_first,
            ctrl_mode,
            ctrl_mstr,
            ctrl_en
        };

        wire [31:0] ss_ctrl_word  = {24'b0, ss_val,    ss_en};
        wire [31:0] int_en_word   = {{(32-IRQ_COUNT){1'b0}}, int_en};
        wire [31:0] int_stat_word = {{(32-IRQ_COUNT){1'b0}}, int_stat};
        wire [31:0] clk_div_word  = {16'b0, clk_div};
        wire [31:0] delay_word    = {24'b0, delay_cfg};

        reg rx_pop_this_cycle;
        always @(*) begin
            rx_pop_this_cycle = 1'b0;
            PRDATA = 32'h0;
            if (apb_read) begin
                case (PADDR)
                    OFF_CTRL    : PRDATA = ctrl_word;
                    OFF_STATUS  : PRDATA = status_word;
                    OFF_TX_DATA : PRDATA = 32'h0;                // WO
                    OFF_RX_DATA : begin
                        PRDATA = rx_empty_w ? 32'h0 : rx_mem[rx_rp[FIFO_AW-1:0]];
                        rx_pop_this_cycle = ~rx_empty_w;         // R15: empty read no OVF
                    end
                    OFF_CLK_DIV : PRDATA = clk_div_word;
                    OFF_SS_CTRL : PRDATA = ss_ctrl_word;
                    OFF_INT_EN  : PRDATA = int_en_word;
                    OFF_INT_STAT: PRDATA = int_stat_word;
                    OFF_DELAY   : PRDATA = delay_word;
                    default     : PRDATA = 32'h0;                // R23
                endcase
            end
        end

        // -------------------------------------------------------------------------
        // TX push side
        // -------------------------------------------------------------------------
        reg tx_push_valid;
        reg [31:0] tx_push_data;

        always @(*) begin
            tx_push_valid = 1'b0;
            tx_push_data  = 32'h0;
            if (apb_write && PADDR == OFF_TX_DATA && ctrl_en) begin
                tx_push_valid = 1'b1;
                case (ctrl_width)
                    2'b00: tx_push_data = {24'b0, PWDATA[7:0]};
                    2'b01: tx_push_data = {16'b0, PWDATA[15:0]};
                    default: tx_push_data = PWDATA;
                endcase
            end
        end

        wire tx_push_accepted = tx_push_valid & ~tx_full_w;
        wire tx_push_dropped  = tx_push_valid &  tx_full_w;   // sets TX_OVF

        // -------------------------------------------------------------------------
        // Configuration register bank
        // -------------------------------------------------------------------------
        always @(posedge PCLK or negedge PRESETn) begin
            if (!PRESETn) begin
                ctrl_en        <= 1'b0;
                ctrl_mstr      <= 1'b0;
                ctrl_mode      <= 2'b00;
                ctrl_lsb_first <= 1'b0;
                ctrl_loopback  <= 1'b0;
                ctrl_width     <= 2'b00;
                clk_div        <= 16'h0;
                ss_en          <= 4'h0;
                ss_val         <= 4'h0;
                int_en         <= '0;
                int_stat       <= '0;
                delay_cfg      <= 8'h0;
            end else begin
                if (apb_write) begin
                    case (PADDR)
                        OFF_CTRL: begin
                            ctrl_width     <= PWDATA[7:6];
                            ctrl_loopback  <= PWDATA[5];
                            ctrl_lsb_first <= PWDATA[4];
                            ctrl_mode      <= PWDATA[3:2];
                            ctrl_mstr      <= PWDATA[1];
                            ctrl_en        <= PWDATA[0];
                        end
                        OFF_CLK_DIV: clk_div <= PWDATA[15:0];
                        OFF_SS_CTRL: begin
                            ss_val <= PWDATA[7:4];
                            ss_en  <= PWDATA[3:0];
                        end
                        OFF_INT_EN : int_en    <= PWDATA[IRQ_COUNT-1:0];
                        OFF_DELAY  : delay_cfg <= PWDATA[7:0];
                        default: ;
                    endcase
                end

                // ----- INT_STAT update (R18 W1C priority) ------------------------
                //   1) default: hold value
                //   2) apply W1C mask
                //   3) OR in new events (so set+clear stays set)
                begin : int_stat_update
                    reg [IRQ_COUNT-1:0] next_stat;
                    next_stat = int_stat;

                    if (apb_write && PADDR == OFF_INT_STAT) begin
                        next_stat = next_stat & ~PWDATA[IRQ_COUNT-1:0];
                    end

                    if (tx_push_dropped)
                        next_stat[IRQ_TX_OVF] = 1'b1;
                    if (rx_push_valid && rx_full_w)
                        next_stat[IRQ_RX_OVF] = 1'b1;
                    if (rx_push_valid && !rx_full_w && (rx_count == FIFO_DEPTH-1))
                        next_stat[IRQ_RX_FULL] = 1'b1;
                    if (tx_pop && (tx_count == 1))
                        next_stat[IRQ_TX_EMPTY] = 1'b1;
                    if (transfer_done_pulse)
                        next_stat[IRQ_TRANSFER_DONE] = 1'b1;

                    int_stat <= next_stat;
                end
            end
        end

        assign IRQ  = |(int_stat & int_en);
        assign SS_n = ~ss_en | ss_val;    // R20

        // -------------------------------------------------------------------------
        // TX FIFO storage
        // -------------------------------------------------------------------------
        integer i;
        always @(posedge PCLK or negedge PRESETn) begin
            if (!PRESETn) begin
                tx_wp <= '0;
                tx_rp <= '0;
                for (i = 0; i < FIFO_DEPTH; i = i + 1) tx_mem[i] <= 32'h0;
            end else if (!ctrl_en) begin
                tx_wp <= '0;
                tx_rp <= '0;
            end else begin
                if (tx_push_accepted) begin
                    tx_mem[tx_wp[FIFO_AW-1:0]] <= tx_push_data;
                    tx_wp <= tx_wp + 1'b1;
                end
                if (tx_pop) begin
                    tx_rp <= tx_rp + 1'b1;
                end
            end
        end

        // -------------------------------------------------------------------------
        // RX FIFO storage
        // -------------------------------------------------------------------------
        always @(posedge PCLK or negedge PRESETn) begin
            if (!PRESETn) begin
                rx_wp <= '0;
                rx_rp <= '0;
                for (i = 0; i < FIFO_DEPTH; i = i + 1) rx_mem[i] <= 32'h0;
            end else if (!ctrl_en) begin
                rx_wp <= '0;
                rx_rp <= '0;
            end else begin
                if (rx_push_valid && !rx_full_w) begin
                    rx_mem[rx_wp[FIFO_AW-1:0]] <= rx_push_data;
                    rx_wp <= rx_wp + 1'b1;
                end
                if (rx_pop_this_cycle) begin
                    rx_rp <= rx_rp + 1'b1;
                end
            end
        end
        // -------------------------------------------------------------------------
        // Outputs to core
        // -------------------------------------------------------------------------
        assign cfg_en        = ctrl_en;
        assign cfg_mstr      = ctrl_mstr;
        assign cfg_mode      = ctrl_mode;
        assign cfg_lsb_first = ctrl_lsb_first;
        assign cfg_loopback  = ctrl_loopback;
        assign cfg_width     = ctrl_width;
        assign cfg_clk_div   = clk_div;
        assign cfg_delay     = delay_cfg;

    endmodule

    ///////////////////////////////////////////////////////////////////////////////////

    module spi_master (
        input  wire         PCLK,
        input  wire         PRESETn,

        // APB slave
        input  wire         PSEL,
        input  wire         PENABLE,
        input  wire         PWRITE,
        input  wire [7:0]   PADDR,
        input  wire [31:0]  PWDATA,
        output wire [31:0]  PRDATA,
        output wire         PREADY,
        output wire         PSLVERR,

        // SPI pins
        output wire         SCLK,
        output wire         MOSI,
        input  wire         MISO,
        output wire [3:0]   SS_n,

        // Interrupt
        output wire         IRQ
    );

        // -------------------------------------------------------------------------
        // Internal regfile <-> core bus
        // -------------------------------------------------------------------------
        wire         cfg_en;
        wire         cfg_mstr;
        wire [1:0]   cfg_mode;
        wire         cfg_lsb_first;
        wire         cfg_loopback;
        wire [1:0]   cfg_width;
        wire [15:0]  cfg_clk_div;
        wire [7:0]   cfg_delay;

        wire [31:0]  tx_word;
        wire         tx_empty;
        wire         tx_pop;

        wire         rx_push_valid;
        wire [31:0]  rx_push_data;

        wire         busy;
        wire         transfer_done_pulse;

        wire [3:0]   ss_n_int;
        assign SS_n = ss_n_int;

        // -------------------------------------------------------------------------
        // Register file + APB slave
        // -------------------------------------------------------------------------
        apb_regfile u_regfile (
            .PCLK                 (PCLK),
            .PRESETn              (PRESETn),

            .PSEL                 (PSEL),
            .PENABLE              (PENABLE),
            .PWRITE               (PWRITE),
            .PADDR                (PADDR),
            .PWDATA               (PWDATA),
            .PRDATA               (PRDATA),
            .PREADY               (PREADY),
            .PSLVERR              (PSLVERR),

            .cfg_en               (cfg_en),
            .cfg_mstr             (cfg_mstr),
            .cfg_mode             (cfg_mode),
            .cfg_lsb_first        (cfg_lsb_first),
            .cfg_loopback         (cfg_loopback),
            .cfg_width            (cfg_width),
            .cfg_clk_div          (cfg_clk_div),
            .cfg_delay            (cfg_delay),

            .SS_n                 (ss_n_int),

            .tx_word              (tx_word),
            .tx_empty             (tx_empty),
            .tx_pop               (tx_pop),

            .rx_push_valid        (rx_push_valid),
            .rx_push_data         (rx_push_data),

            .busy_in              (busy),
            .transfer_done_pulse  (transfer_done_pulse),

            .IRQ                  (IRQ)
        );

        // -------------------------------------------------------------------------
        // SPI shift engine
        // -------------------------------------------------------------------------
        spi_core u_core (
            .PCLK                 (PCLK),
            .PRESETn              (PRESETn),

            .cfg_en               (cfg_en),
            .cfg_mstr             (cfg_mstr),
            .cfg_mode             (cfg_mode),
            .cfg_lsb_first        (cfg_lsb_first),
            .cfg_loopback         (cfg_loopback),
            .cfg_width            (cfg_width),
            .cfg_clk_div          (cfg_clk_div),
            .cfg_delay            (cfg_delay),

            .ss_n_drive           (ss_n_int),

            .tx_word              (tx_word),
            .tx_empty             (tx_empty),
            .tx_pop               (tx_pop),

            .rx_push_valid        (rx_push_valid),
            .rx_push_data         (rx_push_data),

            .busy                 (busy),
            .transfer_done_pulse  (transfer_done_pulse),

            .SCLK                 (SCLK),
            .MOSI                 (MOSI),
            .MISO                 (MISO)
        );

    endmodule




`endif

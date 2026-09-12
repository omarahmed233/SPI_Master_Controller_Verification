`ifndef SPI_SPI_IF_SV
    `define SPI_SPI_IF_SV

`timescale 1ns/1ps


interface spi_slave_ifc (input logic pclk,
                         input logic presetn);

    logic        mosi;
    logic        miso;
    logic [3:0]  ss_n;

    logic       sclk;
    logic [1:0] xfer_mode;    
    logic       xfer_lsb_first;
    logic [1:0] xfer_width;

    clocking cb_slave @(posedge pclk);
        default input #1 output #1;
        input  sclk, mosi, ss_n;
        output miso;
    endclocking

    clocking cb_mon @(posedge pclk);
        default input #1;
        input sclk, mosi, miso, ss_n;
    endclocking

    modport slave   (clocking cb_slave,   input pclk, input sclk, input mosi, input ss_n);
    modport monitor (clocking cb_mon,     input pclk);


    task automatic execute_slave_transfer(
        input  logic [1:0]  mode,
        input  logic [1:0]  width,
        input  logic        lsb_first,
        input  logic [31:0] tx_data,
        output logic [31:0] rx_capture
    );
        logic cpol = mode[1];
        logic cpha = mode[0];
        int   num_bits;
        int   bit_cnt = 0;
        logic [31:0] shift_reg = '0;
        
        logic sclk_q;
        logic sclk_rise, sclk_fall, sample_edge, launch_edge;

        case(width)
            2'b00: num_bits = 8;
            2'b01: num_bits = 16;
            2'b10: num_bits = 32;
            default: num_bits = 8;
        endcase

        // 1. Wait for Chip Select to go active
        wait(ss_n != 4'hF);
        
        // 2. Initialize state
        sclk_q = cpol;
        
        // Pre-launch MISO if CPHA = 0 (Mode 0 or Mode 2)
        if (cpha == 0) begin
            cb_slave.miso <= (lsb_first) ? tx_data[0] : tx_data[num_bits - 1];
        end else begin
            cb_slave.miso <= 1'b0;
        end

        // 3. PCLK Oversampling Loop
        while (ss_n != 4'hF) begin
            @(cb_slave);
            
            // Edge detection
            sclk_rise = (sclk_q == 0 && cb_slave.sclk == 1);
            sclk_fall = (sclk_q == 1 && cb_slave.sclk == 0);
            sclk_q    = cb_slave.sclk;

            sample_edge = (cpol == cpha) ? sclk_rise : sclk_fall;
            launch_edge = (cpol == cpha) ? sclk_fall : sclk_rise;

            // Sample Phase (MOSI)
            if (sample_edge) begin
                if (lsb_first) shift_reg[bit_cnt] = cb_slave.mosi;
                else           shift_reg[num_bits - 1 - bit_cnt] = cb_slave.mosi;
                bit_cnt++;
            end

            // Launch Phase (MISO)
            if (launch_edge) begin
                if (bit_cnt < num_bits) begin
                    cb_slave.miso <= (lsb_first) ? tx_data[bit_cnt] : tx_data[num_bits - 1 - bit_cnt];
                end
            end
            
            // Exit loop if transfer is complete
            if (bit_cnt == num_bits) break; 
        end
        
        // 4. Return captured data and park MISO
        rx_capture = shift_reg;
        wait(ss_n == 4'hF);
        cb_slave.miso <= 1'b0;

    endtask

    task automatic monitor_transaction(
      input  logic [1:0]  mode,
      input  logic [1:0]  width,
      input  logic        lsb_first,
      output logic [31:0] mosi_capture,
      output logic [31:0] miso_capture
  );
      logic cpol = mode[1];
      logic cpha = mode[0];
      int   num_bits;
      int   bit_cnt = 0;
      logic [31:0] mosi_shift = '0;
      logic [31:0] miso_shift = '0;
      
      logic sclk_q;
      logic sclk_rise, sclk_fall, sample_edge;

      case(width)
          2'b00: num_bits = 8;
          2'b01: num_bits = 16;
          2'b10: num_bits = 32;
          default: num_bits = 8;
      endcase

      // 1. Wait for Chip Select to go active
      wait(ss_n != 4'hF);
      
      // 2. Initialize state
      sclk_q = cpol;

      // 3. PCLK Oversampling Loop (Passive observation)
      while (ss_n != 4'hF) begin
          @(cb_mon); // strictly using the monitor clocking block
          
          // Edge detection
          sclk_rise = (sclk_q == 0 && cb_mon.sclk == 1);
          sclk_fall = (sclk_q == 1 && cb_mon.sclk == 0);
          sclk_q    = cb_mon.sclk;

          // Determine when to sample based on SPI Mode
          sample_edge = (cpol == cpha) ? sclk_rise : sclk_fall;

          // Sample Phase (Read both MOSI and MISO)
          if (sample_edge) begin
              if (lsb_first) begin
                  mosi_shift[bit_cnt] = cb_mon.mosi;
                  miso_shift[bit_cnt] = cb_mon.miso;
              end else begin
                  mosi_shift[num_bits - 1 - bit_cnt] = cb_mon.mosi;
                  miso_shift[num_bits - 1 - bit_cnt] = cb_mon.miso;
              end
              bit_cnt++;
          end
          
          // Exit loop if transfer is complete
          if (bit_cnt == num_bits) break; 
      end
      
      // 4. Output the captured data
      mosi_capture = mosi_shift;
      miso_capture = miso_shift;
      
      // 5. Wait for CS to deassert before allowing the next capture
      wait(ss_n == 4'hF);

  endtask

endinterface

`endif
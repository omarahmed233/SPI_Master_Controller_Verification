`ifndef APB_MASTER_IFC_SVH
  `define APB_MASTER_IFC_SVH

`timescale 1ns/1ps

interface apb_master_ifc #(parameter int AW = 8, parameter int DW = 32) (
  input logic pclk,
  input logic presetn
);

  logic              psel;
  logic              penable;
  logic              pwrite;
  logic [AW-1:0]     paddr;
  logic [DW-1:0]     pwdata;
  logic [DW-1:0]     prdata;
  logic              pready;
  logic              pslverr;
  logic              irq;

  clocking cb_master @(posedge pclk);
      default input #1 output #1;
      output psel, penable, pwrite, paddr, pwdata;
      input  prdata, pready, pslverr, irq;
  endclocking

  clocking cb_monitor @(posedge pclk);
      default input #1;
      input psel, penable, pwrite, paddr, pwdata,irq;
      input prdata, pready, pslverr;
  endclocking

  modport master  (clocking cb_master,  input pclk, presetn);
  modport monitor (clocking cb_monitor, input pclk, presetn);

  // =========================================================================
  // BFM Methods (Task-based implementation)
  // =========================================================================

  // Register offsets (Specific to the attached SPI IP)
  localparam [7:0] CTRL     = 8'h00;
  localparam [7:0] STATUS   = 8'h04;
  localparam [7:0] TX_DATA  = 8'h08;
  localparam [7:0] RX_DATA  = 8'h0C;
  localparam [7:0] CLK_DIV  = 8'h10;
  localparam [7:0] SS_CTRL  = 8'h14;
  localparam [7:0] INT_EN   = 8'h18;
  localparam [7:0] INT_STAT = 8'h1C;
  localparam [7:0] DELAY    = 8'h20;

  initial begin
      cb_master.psel    <= 1'b0;
      cb_master.penable <= 1'b0;
      cb_master.pwrite  <= 1'b0;
      cb_master.paddr   <= '0;
      cb_master.pwdata  <= '0;
  end

  task automatic apb_write(input [AW-1:0] addr, input [DW-1:0] data);
      @(cb_master);
      // SETUP phase
      cb_master.psel    <= 1'b1;
      cb_master.penable <= 1'b0;
      cb_master.pwrite  <= 1'b1;
      cb_master.paddr   <= addr;
      cb_master.pwdata  <= data;
      
      @(cb_master);
      // ACCESS phase
      cb_master.penable <= 1'b1;
      
      do @(cb_master); while (!cb_master.pready);
      
      // deassert 
      cb_master.psel    <= 1'b0;
      cb_master.penable <= 1'b0;
      cb_master.pwrite  <= 1'b0;
  endtask

  task automatic apb_read(input [AW-1:0] addr, output [DW-1:0] data);
      @(cb_master);
      // SETUP phase
      cb_master.psel    <= 1'b1;
      cb_master.penable <= 1'b0;
      cb_master.pwrite  <= 1'b0;
      cb_master.paddr   <= addr;
      
      @(cb_master);
      // ACCESS phase
      cb_master.penable <= 1'b1;
      
      do @(cb_master); while (!cb_master.pready);
      
      data = cb_master.prdata;
      
      cb_master.psel    <= 1'b0;
      cb_master.penable <= 1'b0;
  endtask

  // Extension: Helper task to poll the STATUS.BUSY bit (Bit 0)
  task automatic wait_not_busy();
      logic [DW-1:0] status_val;
      do begin
          apb_read(STATUS, status_val);
      end while (status_val[0] == 1'b1);
  endtask

endinterface

`endif
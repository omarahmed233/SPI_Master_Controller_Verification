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

        while (!cb_master.pready)
            @(cb_master);

        // deassert 
        cb_master.psel    <= 1'b0;
        cb_master.penable <= 1'b0;
        cb_master.pwrite  <= 1'b0;
    endtask

    task automatic apb_read(input [AW-1:0] addr);
        @(cb_master);
        // SETUP phase
        cb_master.psel    <= 1'b1;
        cb_master.penable <= 1'b0;
        cb_master.pwrite  <= 1'b0;
        cb_master.paddr   <= addr;

        @(cb_master);
        // ACCESS phase
        cb_master.penable <= 1'b1;

        while (!cb_master.pready)
            @(cb_master);
            
        cb_master.psel    <= 1'b0;
        cb_master.penable <= 1'b0;
    endtask

  task automatic monitor_transaction(
      output logic [AW-1:0]   addr,
      output logic            pwrite,
      output logic [DW-1:0]   wdata,
      output logic [DW-1:0]   rdata
  );
        @(cb_monitor);
        while (!(cb_monitor.psel && cb_monitor.penable))
            @(cb_monitor);

        addr   = cb_monitor.paddr;
        pwrite = cb_monitor.pwrite;
        wdata  = cb_monitor.pwdata;
        rdata  = cb_monitor.prdata;

  endtask


endinterface

`endif
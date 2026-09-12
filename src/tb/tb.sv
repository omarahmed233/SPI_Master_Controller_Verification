`include "RTL.svh"
`include "apb_master_ifc.svh"
`include "spi_slave_ifc.svh"
`include "dut_wrapper.svh"
module testbench();
  
    import uvm_pkg::*;
    import test_pkg::*;

    logic clk;
    logic sys_reset;
    initial begin
    clk = 0;
    forever begin
        clk = #5ns ~clk;
    end
    end

    apb_master_ifc #() apb_ifc(.pclk(clk),.presetn(sys_reset));
    spi_slave_ifc spi_ifc(.pclk(clk),.presetn(sys_reset));

    assign spi_ifc.xfer_mode      = dut_wrapper_dut.u_dut.u_core.xfer_mode;
    assign spi_ifc.xfer_lsb_first = dut_wrapper_dut.u_dut.u_core.xfer_lsb_first;
    assign spi_ifc.xfer_width     = dut_wrapper_dut.u_dut.u_core.xfer_width;

    initial begin
        sys_reset = 0;
        #6;
        sys_reset = 1;
        #150;
        $finish;
    end

    initial begin
        $timeformat(-9, 0, " ns", 5);
        $display("from top module: tb begins");
        uvm_config_db#(virtual apb_master_ifc #())::set(null, "uvm_test_top", "apb_vif", apb_ifc);
        uvm_config_db#(virtual spi_slave_ifc)::set(null, "uvm_test_top", "spi_vif", spi_ifc);
        run_test("");  // specifieed in cmd
    end

    dut_wrapper dut_wrapper_dut(
        .apb(apb_ifc),
        .spi(spi_ifc)
    );
  
endmodule
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

    initial begin
        sys_reset = 1;
        #6;
        sys_reset = 0;
        #30;
        sys_reset = 1;
    end

    initial begin
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
`ifndef spi_monitor_sv
    `define spi_monitor_sv

class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual spi_slave_ifc spi_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("spi monitor","spi monitor constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
endclass

`endif
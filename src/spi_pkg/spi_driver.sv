`ifndef spi_driver_sv
  `define spi_driver_sv

class spi_driver extends uvm_driver #(spi_seq_item);
  `uvm_component_utils(spi_driver)

  virtual spi_slave_ifc spi_vif;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("spi driver","spi driver constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
endclass

`endif
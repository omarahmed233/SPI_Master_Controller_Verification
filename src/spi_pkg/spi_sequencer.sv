`ifndef spi_sequencer_sv
  `define spi_sequencer_sv

class spi_sequencer extends uvm_sequencer#(spi_seq_item);

  `uvm_component_utils(spi_sequencer)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("spi sequencer","spi_sequencer constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
  endfunction
  
endclass

`endif
`ifndef apb_sequencer_sv
  `define apb_sequencer_sv

class apb_sequencer extends uvm_sequencer#(apb_seq_item);

  `uvm_component_utils(apb_sequencer)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("apb dequencer","apb_sequencer constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
endclass

`endif
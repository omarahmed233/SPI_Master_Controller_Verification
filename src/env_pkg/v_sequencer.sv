`ifndef v_sequencer_sv
  `define v_sequencer_sv

class v_sequencer extends uvm_sequencer;
  `uvm_component_utils(v_sequencer)

  spi_sequencer spi_sequencer_instance;
  apb_sequencer apb_sequencer_instance;
  

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("Virtual sequencer","constructing virtual sequencer", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    spi_sequencer_instance = spi_sequencer::type_id::create("spi_sequencer_instance", this);
    apb_sequencer_instance = apb_sequencer::type_id::create("apb_sequencer_instance", this);
  endfunction
  
endclass

`endif
`ifndef apb_driver_sv
  `define apb_driver_sv

class apb_driver extends uvm_driver #(apb_seq_item);
  `uvm_component_utils(apb_driver)

  virtual apb_master_ifc #() apb_vif;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("apb driver","apb driver constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
endclass

`endif
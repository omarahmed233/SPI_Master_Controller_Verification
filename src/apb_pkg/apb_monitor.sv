`ifndef apb_monitor_sv
    `define apb_monitor_sv

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_master_ifc #() apb_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("apb monitor","apb monitor constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
endclass

`endif
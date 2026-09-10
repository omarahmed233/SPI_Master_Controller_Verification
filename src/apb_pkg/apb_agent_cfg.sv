`ifndef apb_agent_cfg_sv
    `define apb_agent_cfg_sv

class apb_agent_cfg extends uvm_object;
  `uvm_object_utils(apb_agent_cfg)

  uvm_active_passive_enum is_active;
  
  virtual apb_master_ifc #() apb_vif;

  function new(string name = "apb_agent_cfg");
    super.new(name);
    `uvm_info("apb agent configuration","apb config constructor", UVM_HIGH) 
  endfunction
  
endclass

`endif
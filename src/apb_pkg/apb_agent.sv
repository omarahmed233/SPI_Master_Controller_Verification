`ifndef apb_agent_sv
    `define apb_agent_sv

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  apb_agent_cfg agent_cfg;
  
  apb_sequencer sqr;
  apb_driver    drv;
  apb_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("APB_AGENT", "apb agent first constructor", UVM_HIGH)
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(apb_agent_cfg)::get(this, "", "apb_configuration", agent_cfg)) begin
      `uvm_fatal("NO_CFG", "Could not find apb_configuration in uvm_config_db")
    end

    mon = apb_monitor::type_id::create("mon", this);
    mon.apb_vif = agent_cfg.apb_vif;

    if (agent_cfg.is_active == UVM_ACTIVE) begin
      sqr = apb_sequencer::type_id::create("sqr", this);
      drv = apb_driver::type_id::create("drv", this);
      drv.apb_vif = agent_cfg.apb_vif;
    end

  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass

`endif
`ifndef my_env_sv
  `define my_env_sv

class my_env extends uvm_env;
  `uvm_component_utils(my_env)
  
  apb_agent apb_agent_instance;
  spi_agent spi_agent_instance;

  v_sequencer v_sequencer_instance;
  
  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("env","env constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agent_instance = apb_agent::type_id::create("apb_agent_instance", this);
    spi_agent_instance = spi_agent::type_id::create("spi_agent_instance", this);
    v_sequencer_instance = v_sequencer::type_id::create("v_sequencer_instance", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    v_sequencer_instance.apb_sequencer_instance = apb_agent_instance.sqr;
    v_sequencer_instance.spi_sequencer_instance = spi_agent_instance.sqr;
  endfunction
  
endclass

`endif
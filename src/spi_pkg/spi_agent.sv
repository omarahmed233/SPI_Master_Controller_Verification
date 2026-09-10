`ifndef spi_agent_sv
    `define spi_agent_sv

class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)
  
  spi_agent_cfg agent_cfg; 
  
  spi_sequencer sqr;
  spi_driver    drv;
  spi_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("SPI_AGENT", "spi agent constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(spi_agent_cfg)::get(this, "", "spi_configuration", agent_cfg)) begin
      `uvm_fatal("NO_CFG", "Could not find spi_configuration in uvm_config_db")
    end

    mon = spi_monitor::type_id::create("mon", this);
    mon.spi_vif = agent_cfg.spi_vif;

    if (agent_cfg.is_active == UVM_ACTIVE) begin
      sqr = spi_sequencer::type_id::create("sqr", this);
      drv = spi_driver::type_id::create("drv", this);
      drv.spi_vif = agent_cfg.spi_vif
    end

  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass

`endif
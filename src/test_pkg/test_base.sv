`ifndef test_base_svh
  `define test_base_svh

class test_base extends uvm_test;
  `uvm_component_utils(test_base)
  
  my_env env;
  spi_agent_cfg spi_cfg; 
  apb_agent_cfg apb_cfg;

  virtual apb_master_ifc #() get_apb_vif;
  virtual spi_slave_ifc get_spi_vif;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("test base","test constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
    spi_cfg = spi_agent_cfg::type_id::create("spi_cfg");
    apb_cfg = apb_agent_cfg::type_id::create("apb_cfg");


    if (!uvm_config_db#(virtual apb_master_ifc #())::get(this, "", "apb_vif", get_apb_vif)) begin
      `uvm_fatal("NO_VIF", "Could not find apb_vif in uvm_config_db")
    end

    if (!uvm_config_db#(virtual spi_slave_ifc)::get(this, "", "spi_vif", get_spi_vif)) begin
      `uvm_fatal("NO_VIF", "Could not find spi_vif in uvm_config_db")
    end

    spi_cfg.is_active = UVM_ACTIVE;
    apb_cfg.is_active = UVM_ACTIVE;

    spi_cfg.spi_vif = get_spi_vif;
    apb_cfg.apb_vif = get_apb_vif;

    uvm_config_db#(spi_agent_cfg)::set(this, "env.spi_agent_instance", "spi_configuration", spi_cfg);
    uvm_config_db#(apb_agent_cfg)::set(this, "env.apb_agent_instance", "apb_configuration", apb_cfg);

  endfunction
  
endclass

`endif
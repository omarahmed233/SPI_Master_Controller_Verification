`ifndef spi_agent_cfg_sv
    `define spi_agent_cfg_sv

class spi_agent_cfg extends uvm_object;
  `uvm_object_utils(spi_agent_cfg)

  uvm_active_passive_enum is_active;

  virtual spi_slave_ifc spi_vif;

  function new(string name = "spi_agent_cfg");
    super.new(name);
    `uvm_info("spi configuration","spi config constructor", UVM_HIGH) 

  endfunction
  
endclass

`endif
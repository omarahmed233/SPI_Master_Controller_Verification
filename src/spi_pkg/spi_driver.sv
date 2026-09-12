`ifndef spi_driver_sv
  `define spi_driver_sv

class spi_driver extends uvm_driver #(spi_seq_item);
  `uvm_component_utils(spi_driver)

  virtual spi_slave_ifc spi_vif;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("spi driver","spi driver constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Initial drive states
    // spi_vif.miso <= 1'b0;

    forever begin
      // Get the next transaction item from the sequencer
      seq_item_port.get_next_item(req);
      `uvm_info("SPI_DRIVER", $sformatf("[%0t] Preparing SPI Slave Response | Payload (MISO): 0x%0h", 
                $time, req.miso_data), UVM_MEDIUM)
      seq_item_port.item_done();
    end
  endtask
  
endclass

`endif
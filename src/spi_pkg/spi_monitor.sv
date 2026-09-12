`ifndef SPI_MONITOR_SV
  `define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual spi_slave_ifc spi_vif;
  uvm_analysis_port #(spi_seq_item) spi_monitor_port;
  spi_seq_item spi_monitor_item; 

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    spi_monitor_item = spi_seq_item::type_id::create("spi_monitor_item");
    spi_monitor_port = new("spi_monitor_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);

    forever begin

      wait(spi_vif.presetn == 1'b1);
      spi_vif.monitor_transaction(
        .mode(spi_vif.xfer_mode),
        .width(spi_vif.xfer_width),
        .lsb_first(spi_vif.xfer_lsb_first),
        .mosi_capture(spi_monitor_item.mosi_data),
        .miso_capture(spi_monitor_item.miso_data)
      );

      spi_monitor_item.mode      = spi_vif.xfer_mode;
      spi_monitor_item.width     = spi_vif.xfer_width;
      spi_monitor_item.lsb_first = spi_vif.xfer_lsb_first;

      `uvm_info("SPI_MON", $sformatf("[%0t] Captured SPI Transfer | MOSI: 0x%0h | MISO: 0x%0h | Mode: %0d", 
                $time, spi_monitor_item.mosi_data, spi_monitor_item.miso_data, spi_monitor_item.mode), UVM_MEDIUM)

      spi_monitor_port.write(spi_monitor_item);
    end
  endtask
endclass

`endif
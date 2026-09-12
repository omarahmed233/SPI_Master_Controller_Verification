`ifndef APB_MONITOR_SV
  `define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_master_ifc apb_vif;
  uvm_analysis_port #(apb_seq_item) apb_monitor_port;
  apb_seq_item apb_monitor_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("APB_MON", "apb monitor constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_monitor_port = new("apb_monitor_port", this);
    apb_monitor_item = apb_seq_item::type_id::create("apb_monitor_item");
  endfunction

  virtual task run_phase(uvm_phase phase);

    forever begin

      apb_vif.monitor_transaction(
        .addr  (apb_monitor_item.paddr),
        .pwrite(apb_monitor_item.pwrite),
        .wdata (apb_monitor_item.pwdata),
        .rdata (apb_monitor_item.prdata)
      );

     `uvm_info("APB_MON", 
          $sformatf("[%0t] Captured APB %s | Addr: 0x%0h | Data: 0x%0h", 
                    $time, 
                    (apb_monitor_item.pwrite ? "WRITE" : "READ"), 
                    apb_monitor_item.paddr, 
                    (apb_monitor_item.pwrite ? apb_monitor_item.pwdata : apb_monitor_item.prdata)), 
          UVM_MEDIUM)
          
      apb_monitor_port.write(apb_monitor_item);
    end
  endtask
  
endclass

`endif
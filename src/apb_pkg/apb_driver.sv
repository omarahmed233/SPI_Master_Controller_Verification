`ifndef apb_driver_sv
  `define apb_driver_sv

class apb_driver extends uvm_driver #(apb_seq_item);
  `uvm_component_utils(apb_driver)

  virtual apb_master_ifc #() apb_vif;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    `uvm_info("apb driver","apb driver constructor", UVM_HIGH) 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    

    forever begin
      seq_item_port.get_next_item(req);
     `uvm_info("APB_DRIVER", 
          $sformatf("[%0t] Executing APB %s | Addr: 0x%0h | Data: 0x%0h", 
                    $time, 
                    (req.pwrite ? "WRITE" : "READ"), 
                    req.paddr, 
                    (req.pwrite ? req.pwdata : req.prdata)), UVM_MEDIUM)
      if(req.pwrite) apb_vif.apb_write(req.paddr, req.pwdata);
      else apb_vif.apb_read(req.paddr) ;
      seq_item_port.item_done();
    end
  endtask
  
endclass

`endif
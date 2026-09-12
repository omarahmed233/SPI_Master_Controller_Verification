`ifndef APB_SEQUENCE_SV
    `define APB_SEQUENCE_SV

class apb_sequence extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_sequence)

  function new(string name = "apb_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("APB_SEQ", "Starting basic APB sequence", UVM_LOW)

    // Allocate fresh memory for the request item
    req = apb_seq_item::type_id::create("req");
    
    start_item(req);
    if (!req.randomize()) begin
      `uvm_error("APB_SEQ", "Randomization failed for APB item")
    end
    finish_item(req);

    `uvm_info("APB_SEQ", "Basic APB sequence completed", UVM_LOW)
  endtask

endclass

`endif
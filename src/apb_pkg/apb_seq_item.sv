`ifndef apb_seq_item_sv
  `define apb_seq_item_sv

class apb_seq_item extends uvm_sequence_item;

  `uvm_object_utils(apb_seq_item)
  
  function new(string name = "");
    super.new(name);
    `uvm_info("apb sequence item","apb_seq_item construction", UVM_HIGH) 
  endfunction
  
endclass

`endif
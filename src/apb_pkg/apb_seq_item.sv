`ifndef apb_seq_item_sv
  `define apb_seq_item_sv

class apb_seq_item extends uvm_sequence_item;

  `uvm_object_utils(apb_seq_item)

  rand bit [7:0]  paddr;   
  rand bit        pwrite;  
  rand bit [31:0] pwdata; 

  bit [31:0]      prdata;  
  bit             pslverr;
  
  function new(string name = "apb_seq_item");
    super.new(name);
    `uvm_info("APB_SEQ_ITEM", "apb_seq_item construction", UVM_HIGH) 
  endfunction
  
endclass

`endif
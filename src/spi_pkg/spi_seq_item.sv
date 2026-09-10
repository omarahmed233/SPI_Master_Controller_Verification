`ifndef spi_seq_item_sv
  `define spi_seq_item_sv

class spi_seq_item extends uvm_sequence_item;

  `uvm_object_utils(spi_seq_item)
  
  function new(string name = "");
    super.new(name);
    `uvm_info("spi sequence item","spi_seq_item construction", UVM_HIGH) 
  endfunction
  
endclass

`endif
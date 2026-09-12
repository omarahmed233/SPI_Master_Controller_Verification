`ifndef SPI_SEQ_ITEM_SV
  `define SPI_SEQ_ITEM_SV

class spi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(spi_seq_item)

  rand logic [31:0] miso_data; 
  logic [31:0]      mosi_data;
  logic [3:0]       ss_n;         
  logic [1:0]       mode;    
  logic             lsb_first;
  logic [1:0]       width;

  function new(string name = "spi_seq_item");
    super.new(name);
    `uvm_info("SPI_SEQ_ITEM", "spi_seq_item construction", UVM_HIGH) 
  endfunction
  
endclass

`endif
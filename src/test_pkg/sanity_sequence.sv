`ifndef SANITY_SEQUENCE_SV
    `define SANITY_SEQUENCE_SV

class sanity_sequence extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(sanity_sequence)

  function new(string name = "sanity_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SANITY_SEQ", "Starting Sanity Test: Mode 0, 1-byte TX", UVM_LOW)

    // 1. Write to CTRL (0x00) - Enable SPI, Mode 0
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { paddr == 8'h00; pwrite == 1'b1; pwdata == 32'h0000_0003; }) begin
      `uvm_error("SANITY_SEQ", "Randomization failed for CTRL write")
    end
    finish_item(req);

    // 2. Write to SS_CTRL (0x14) - Assert SS_N lane 0
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { paddr == 8'h14; pwrite == 1'b1; pwdata == 32'h0000_000E; }) begin
      `uvm_error("SANITY_SEQ", "Randomization failed for SS_CTRL write")
    end
    finish_item(req);

    // 3. Write to TX_DATA (0x08) - Transmit 1 byte (0x5A)
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { paddr == 8'h08; pwrite == 1'b1; pwdata == 32'h0000_005A; }) begin
      `uvm_error("SANITY_SEQ", "Randomization failed for TX_DATA write")
    end
    finish_item(req);

    `uvm_info("SANITY_SEQ", "Sanity Test Completed", UVM_LOW)
  endtask

endclass

`endif
`ifndef v_sequence_sv
  `define v_sequence_sv

class v_sequence extends uvm_sequence;
    `uvm_object_utils(v_sequence)
    `uvm_declare_p_sequencer(v_sequencer)

    function new(string name = "");
        super.new(name);
        `uvm_info("virtual sequence","my virtual sequence", UVM_HIGH) 
    endfunction

    virtual task pre_body();
    // factory create sequences
    endtask

    virtual task body();
    endtask

endclass

`endif
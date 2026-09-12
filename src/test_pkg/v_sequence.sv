`ifndef V_SEQUENCE_SV
`define V_SEQUENCE_SV

class v_sequence extends uvm_sequence;
    `uvm_object_utils(v_sequence)
    `uvm_declare_p_sequencer(v_sequencer)

    sanity_sequence seq1;
    apb_sequence seq2;
    
    function new(string name = "v_sequence");
        super.new(name);
        `uvm_info("V_SEQ", "my virtual sequence construction", UVM_HIGH) 
    endfunction

    virtual task pre_body();
        seq1 = sanity_sequence::type_id::create("seq1");
        seq2 = apb_sequence::type_id::create("seq2"); 
    endtask

    virtual task body();
        `uvm_info("V_SEQ", "Starting virtual sequence body", UVM_LOW)
        seq1.start(p_sequencer.apb_sequencer_instance);
        seq2.start(p_sequencer.apb_sequencer_instance);
        `uvm_info("V_SEQ", "Virtual sequence completed", UVM_LOW)
    endtask

endclass

`endif
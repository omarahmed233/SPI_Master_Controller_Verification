`ifndef spi_pkg_sv
    `define spi_pkg_sv

    `include "uvm_macros.svh"

    package spi_pkg;
        import uvm_pkg::*;
        `include "spi_seq_item.sv"
        `include "spi_sequencer.sv"
        `include "spi_driver.sv"
        `include "spi_monitor.sv"
        `include "spi_agent_cfg.sv"
        `include "spi_agent.sv"
    endpackage

`endif
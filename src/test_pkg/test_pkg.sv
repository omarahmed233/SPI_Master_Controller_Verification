`ifndef test_pkg_sv
  `define test_pkg_sv

`include "uvm_macros.svh"

package test_pkg;
  import uvm_pkg::*;
  import env_pkg::*;
  import apb_pkg::*;
  import spi_pkg::*;
  `include "test_base.sv"
endpackage

`endif
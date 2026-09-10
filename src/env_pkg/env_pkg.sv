`ifndef env_pkg_sv
  `define env_pkg_sv

`include "uvm_macros.svh"

package env_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  import spi_pkg::*;
  `include "my_env.sv"
endpackage

`endif
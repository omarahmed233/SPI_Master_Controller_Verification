
vlog -work work -vopt -sv -stats=none src/apb_pkg/apb_pkg.sv 
vlog -work work -vopt -sv -stats=none src/spi_pkg/spi_pkg.sv 
vlog -work work -vopt -sv -stats=none src/env_pkg/env_pkg.sv 
vlog -work work -vopt -sv -stats=none src/test_pkg/test_pkg.sv
vlog -work work -vopt -sv -stats=none src/tb/tb.sv

vsim testbench "+UVM_TESTNAME=test_base" "+UVM_VERBOSITY=UVM_MEDIUM"

run -all

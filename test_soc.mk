# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
PROG_FILE ?= test.mem
START_SIG ?= 0
END_SIG ?= 0

VERILOG_SOURCES += $(PWD)/register.v $(PWD)/alu.v $(PWD)/core.v $(PWD)/shift.v $(PWD)/cpu.v $(PWD)/top.v $(PWD)/tb_top_with_ram.v $(PWD)/ledscan.v $(PWD)/sim_sram.v $(PWD)/uart/uart_tx.v
COMPILE_ARGS    += -DSIM -DPROG_FILE=\"$(PROG_FILE)\" -DSTART_SIG=$(START_SIG) -DEND_SIG=$(END_SIG)

COMPILE_ARGS += -DICE40 -DNO_ICE40_DEFAULT_ASSIGNMENTS
VERILOG_SOURCES += $(PWD)/ice40_cells_sim.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_top_with_ram

# MODULE is the basename of the Python test file
MODULE = test_soc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

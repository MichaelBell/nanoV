# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/register.v $(PWD)/alu.v $(PWD)/core.v $(PWD)/shift.v $(PWD)/tb_alu_register.v
COMPILE_ARGS    += -DSIM

COMPILE_ARGS += -DICE40 -DNO_ICE40_DEFAULT_ASSIGNMENTS
VERILOG_SOURCES += $(PWD)/ice40_cells_sim.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_alu_register

# MODULE is the basename of the Python test file
MODULE = test_alu_register

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/register.v $(PWD)/alu.v $(PWD)/core.v $(PWD)/shift.v $(PWD)/multiply.v $(PWD)/cpu.v $(PWD)/tb_cpu.v
COMPILE_ARGS    += -DSIM

COMPILE_ARGS += -DICE40 -DNO_ICE40_DEFAULT_ASSIGNMENTS
VERILOG_SOURCES += $(PWD)/ice40_cells_sim.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
ifeq ($(TOP),yes)
TOPLEVEL = tb_top
VERILOG_SOURCES += $(PWD)/top.v $(PWD)/tb_top.v $(PWD)/ledscan.v $(PWD)/musicnote.v $(PWD)/uart/uart_tx.v $(PWD)/uart/uart_rx.v
else
TOPLEVEL = tb_cpu
endif

# MODULE is the basename of the Python test file
MODULE = test_cpu

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

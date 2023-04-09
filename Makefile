# Project setup
PROJ      = nanoV

# Files
FILES = ledscan.v big_7seg.v top.v core.v alu.v register.v shift.v

.PHONY: iceFUN clean burn

iceFUN:
	# Synthesize using Yosys
	yosys -p "synth_ice40 -top nanoV_top -json $(PROJ).json" -DICE40 $(FILES) > yosys.log
	@grep Warn yosys.log || true
	@grep Error yosys.log || true
	@echo

	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --pre-pack timing.py --asc $(PROJ).asc --opt-timing --pcf iceFUN.pcf > nextpnr.log 2>& 1
	@grep Warn nextpnr.log || true
	@grep Error nextpnr.log || true
	@grep "Max frequency.*cpu_clk" nextpnr.log | tail -1
	@echo

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm *.asc *.bin *blif

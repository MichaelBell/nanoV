# Project setup
PROJ      = nanoV

# Files
FILES = ledscan.v big_7seg.v top.v core.v alu.v register.v shift.v cpu.v uart/uart_tx.v uart/uart_rx.v

.PHONY: iceFUN stats synth clean burn

iceFUN: synth
	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

synth:
	# Synthesize using Yosys
	yosys -p "synth_ice40 -top nanoV_top -json $(PROJ).json" -DICE40 -DSLOW $(FILES) > yosys.log
	@grep Warn yosys.log || true
	@grep Error yosys.log || true
	@grep "   Number of cells" yosys.log
	@grep "     SB_DFF" yosys.log | awk '{sum+=$$2;}END{printf("     SB_DFF* %25d\n", sum);}'
	@grep "     SB_LUT" yosys.log
	@echo

	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --pre-pack timing.py --asc $(PROJ).asc --opt-timing --pcf iceFUN.pcf > nextpnr.log 2>& 1
	@grep Warn nextpnr.log || true
	@grep Error nextpnr.log || true
	@grep "Max frequency.*clk12MHz" nextpnr.log | tail -1
	@echo

stats:
	@grep Warn yosys.log || true
	@grep Error yosys.log || true
	@grep Warn nextpnr.log || true
	@grep Error nextpnr.log || true
	@grep "Max frequency.*clk12MHz" nextpnr.log | tail -1
	@echo "| Item | Count |"
	@echo "| ---- | ----- |"
	@grep "   Number of cells" yosys.log | awk '{printf("| Cells | %s |\n", $$4);}'
	@grep "     SB_DFF" yosys.log | awk '{sum+=$$2;}END{printf("| SB_DFF* | %d |\n", sum);}'
	@grep "     SB_LUT" yosys.log | awk '{printf("| %s | %s |\n", $$1, $$2);}'
	@grep "     ICESTORM_LC" nextpnr.log | awk '{gsub(/\//, "", $$3);printf("| ICE40 LCs | %s |\n", $$3);}'

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm *.asc *.bin

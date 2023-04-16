import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

# Just executes whatever is in test.mem so you can inspect the waveform
# https://riscvasm.lucasteske.dev/# is useful for assembling hex for the file.
@cocotb.test()
async def test_start(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    await ClockCycles(nv.clk, 3200)

    del clock
    for i in range(nv.start_sig.value.integer >> 2, nv.end_sig.value.integer >> 2):
        debug_clock = Clock(nv.debug_clk, 10, units="ns")
        cocotb.start_soon(debug_clock.start())
        nv.debug_addr.value = i
        await ClockCycles(nv.debug_clk, 2)
        print("{:08x}".format(nv.debug_data.value.integer))
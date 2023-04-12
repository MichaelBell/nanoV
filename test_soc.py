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

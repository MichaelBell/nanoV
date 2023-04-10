import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

from riscvmodel.insn import *
from riscvmodel.regnames import x0, x1, x2, x3

@cocotb.test()
async def test_start(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 30)
    assert nv.spi_select.value == 1    

    read_cmd = 3
    for i in range(8):
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == (1 if (read_cmd & (0x80 >> i)) != 0 else 0)

    # Address after reset is 0.
    for i in range(24):    
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == 0

    # Simulate buffer latency
    await ClockCycles(nv.clk, 1)

    # Now flow in a command
    instr = InstructionADDI(x1, x0, 279).encode()
    for i in range(32):
        nv.spi_data_in = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
    
    instr = InstructionSW(x0, x1, 0).encode()
    for i in range(32):
        nv.spi_data_in = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)

    instr = InstructionNOP().encode()
    for i in range(32):
        nv.spi_data_in = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)

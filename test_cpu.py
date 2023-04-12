import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

from riscvmodel.insn import *
from riscvmodel.regnames import x0, x1, x2, x3

async def do_start(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 30)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1    

async def expect_read(nv, addr):
    read_cmd = 3
    for i in range(8):
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == (1 if (read_cmd & (0x80 >> i)) != 0 else 0)

    # Address after reset is 0.
    for i in range(24):    
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == (1 if (addr & (0x800000 >> i)) != 0 else 0)

async def send_instr(nv, instr):
    # Simulate buffer latency
    await Timer(1, "ns")

    for i in range(32):
        nv.spi_data_in.value = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
        await Timer(1, "ns")

@cocotb.test()
async def test_start(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionADDI(x1, x0, 279).encode())
    await send_instr(nv, InstructionSW(x0, x1, 0).encode())
    await send_instr(nv, InstructionNOP().encode())
    await send_instr(nv, InstructionNOP().encode())    

@cocotb.test()
async def test_jmp(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionNOP().encode())          # 0
    await send_instr(nv, InstructionJAL(x1, 320).encode())   # 4 -> 324

    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 3)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 28)
    assert nv.spi_select.value == 1

    await expect_read(nv, 324)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionSW(x0, x1, 0).encode())  # 324
    await send_instr(nv, InstructionJAL(x1, 12000).encode()) # 328 -> 12328

    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 3)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 28)
    assert nv.spi_select.value == 1

    await expect_read(nv, 12328)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionSW(x0, x1, 0).encode()) # 12328
    await send_instr(nv, InstructionNOP().encode())
    await send_instr(nv, InstructionNOP().encode())

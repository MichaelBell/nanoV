import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

@cocotb.test()
async def test_registers(reg):
    clock = Clock(reg.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    reg.rstn.value = 0
    await ClockCycles(reg.clk, 2)
    reg.rstn.value = 1
    reg.wr_en.value = 1
    reg.wr_en_next.value = 0
    reg.read_through.value = 0
    await ClockCycles(reg.clk, 1)

    reg.rs1.value = 1
    reg.rs2.value = 2
    reg.rd.value = 1

    reg.rd_in.value = 0x12345679
    await ClockCycles(reg.clk, 32)

    reg.wr_en.value = 0
    await ClockCycles(reg.clk, 32)

    reg.wr_en.value = 1
    reg.rd_in.value = 0xA5948372
    await ClockCycles(reg.clk, 1)
    assert reg.rs1_out.value == 0x12345679
    await ClockCycles(reg.clk, 31)

    reg.wr_en.value = 0
    await ClockCycles(reg.clk, 32)
    reg.rs1.value = 0
    await ClockCycles(reg.clk, 1)
    assert reg.rs1_out.value == 0xA5948372

    await ClockCycles(reg.clk, 32)
    assert reg.rs1_out.value == 0

    j = 0
    val = 0

    for i in range(100):
        await ClockCycles(reg.clk, 31)

        reg.rs1.value = j
        await ClockCycles(reg.clk, 1)

        reg.wr_en.value = 0
        await ClockCycles(reg.clk, 32)

        last_val = val
        last_j = j
        val = random.randint(0, 0xFFFFFFFF)
        j = random.randint(0, 15)

        reg.wr_en.value = 1
        reg.rd_in.value = val
        reg.rd.value = j

        await ClockCycles(reg.clk, 1)
        assert reg.rs1_out.value == (0 if last_j == 0 else last_val)

    k = 0
    val2 = 0
    for i in range(100):
        await ClockCycles(reg.clk, 31)

        reg.wr_en.value = 1
        reg.rd_in.value = val2
        reg.rd.value = k
        await ClockCycles(reg.clk, 31)

        reg.rs1.value = j
        reg.rs2.value = k
        await ClockCycles(reg.clk, 1)

        reg.wr_en.value = 0
        await ClockCycles(reg.clk, 32)

        last_val, last_val2 = val, val2
        last_j, last_k = j, k
        val = random.randint(0, 0xFFFFFFFF)
        val2 = random.randint(0, 0xFFFFFFFF)
        j = random.randint(0, 15)
        k = (j + 1) & 0xF

        reg.wr_en.value = 1
        reg.rd_in.value = val
        reg.rd.value = j

        await ClockCycles(reg.clk, 1)
        assert reg.rs1_out.value == (0 if last_j == 0 else last_val)
        assert reg.rs2_out.value == (0 if last_k == 0 else last_val2)

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

from riscvmodel.insn import *
from riscvmodel.regnames import x0, x1, x2, x4, x5, x6

pc = 0

async def do_start(nv):
    global pc
    pc = 0

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

async def expect_spi_cmd(nv, addr, cmd):
    for i in range(8):
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == (1 if (cmd & (0x80 >> i)) != 0 else 0)

    # Address after reset is 0.
    for i in range(24):    
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        assert nv.spi_out.value == (1 if (addr & (0x800000 >> i)) != 0 else 0)

async def expect_read(nv, addr):
    await expect_spi_cmd(nv, addr, 3)

async def expect_write(nv, addr):
    await expect_spi_cmd(nv, addr, 2)

async def send_instr(nv, instr):
    global pc
    pc += 4

    # Simulate buffer latency
    await Timer(1, "ns")

    for i in range(32):
        nv.spi_data_in.value = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
        await Timer(1, "ns")

async def get_reg_value(nv, reg, bits=32):
    addr = random.randint(0, 255) * 4
    if bits == 32:
        await send_instr(nv, InstructionSW(x0, reg, addr).encode())
    elif bits == 16:
        await send_instr(nv, InstructionSH(x0, reg, addr).encode())
    else:
        assert bits == 8
        await send_instr(nv, InstructionSB(x0, reg, addr).encode())

    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 22)
    assert nv.spi_select.value == 1

    await expect_write(nv, addr)

    data = 0
    shift = 0
    for i in range(bits):
        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 0
        data |= nv.spi_out.value.integer << shift
        shift += 1

    await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 5 + (32 - bits))
    assert nv.spi_select.value == 1

    if hasattr(nv, "addr"): assert nv.addr.value == addr
    if hasattr(nv, "data"):assert (nv.data.value & ((1 << bits) - 1)) == data

    await expect_read(nv, pc)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    return data

async def load_reg(nv, reg, val, bits=32, signed=False, external=False):
    addr = random.randint(0, 255) * 4
    base_reg = x0
    if external:
        await send_instr(nv, InstructionLUI(x6, 0x10000).encode())
        base_reg = x6
    if bits == 32:
        await send_instr(nv, InstructionLW(reg, base_reg, addr).encode())
    elif bits == 16:
        if signed: await send_instr(nv, InstructionLH(reg, base_reg, addr).encode())
        else: await send_instr(nv, InstructionLHU(reg, base_reg, addr).encode())
    else:
        assert bits == 8
        if signed: await send_instr(nv, InstructionLB(reg, base_reg, addr).encode())
        else: await send_instr(nv, InstructionLBU(reg, base_reg, addr).encode())

    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1

    if external:
        if nv.is_buffered.value == 0:
            await ClockCycles(nv.clk, 1)
        await ClockCycles(nv.clk, 30)
        assert nv.store_addr_out.value == 1
        assert nv.addr_out.value == addr + 0x10000000

        nv.ext_data_in.value = val
        await ClockCycles(nv.clk, 61)
        if nv.is_buffered.value == 1:
            await ClockCycles(nv.clk, 1)
    else:
        await ClockCycles(nv.clk, 22)
        assert nv.spi_select.value == 1

        await expect_read(nv, addr)

        if nv.is_buffered.value == 0:
            await ClockCycles(nv.clk, 1)

        # Simulate buffer latency
        await Timer(1, "ns")

        for i in range(bits):
            nv.spi_data_in.value = (val >> i) & 1
            await ClockCycles(nv.clk, 1)
            await Timer(1, "ns")
        
        if nv.is_buffered.value == 1:
            await ClockCycles(nv.clk, 1)

        await ClockCycles(nv.clk, 1)
        assert nv.spi_select.value == 1
        await ClockCycles(nv.clk, 4 + (32 - bits))

    assert nv.spi_select.value == 1

    await expect_read(nv, pc)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)


@cocotb.test()
async def test_start(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionADDI(x1, x0, 279).encode())
    assert await get_reg_value(nv, x1) == 279
    await send_instr(nv, InstructionAUIPC(x2, 1).encode())
    assert await get_reg_value(nv, x2) == (1 << 12) + 8

@cocotb.test()
async def test_jmp(nv):
    global pc
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

    pc = 324
    assert await get_reg_value(nv, x1) == 8                  # 324
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

    pc = 12328
    assert await get_reg_value(nv, x1) == 332                 # 12328
    await send_instr(nv, InstructionJALR(x5, x1, 0).encode()) # 12332 -> 332

    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 3)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 28)
    assert nv.spi_select.value == 1

    await expect_read(nv, 332)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    pc = 332
    assert await get_reg_value(nv, x5) == 12336                # 332
    await send_instr(nv, InstructionADDI(x2, x0, 80).encode()) # 336
    await send_instr(nv, InstructionJALR(x5, x2, 0).encode())  # 340 -> 80

    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 3)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 28)
    assert nv.spi_select.value == 1

    await expect_read(nv, 80)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    pc = 80
    assert await get_reg_value(nv, x5) == 344                # 80
    await send_instr(nv, InstructionJAL(x1, -40).encode())   # 84 -> 44

    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 3)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 28)
    assert nv.spi_select.value == 1

    await expect_read(nv, 44)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    pc = 44
    assert await get_reg_value(nv, x1) == 88                 # 44
    await send_instr(nv, InstructionNOP().encode())
    await send_instr(nv, InstructionNOP().encode())

@cocotb.test()
async def test_branch(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionADDI(x1, x0, -4).encode())  # 0
    await send_instr(nv, InstructionBLT(x1, x0, 120).encode())      # 4 -> 124

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 29)
    assert nv.spi_select.value == 1

    await expect_read(nv, 124)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionBLT(x0, x1, 20).encode())  # 124
    await send_instr(nv, InstructionBLTU(x0, x1, 2000).encode()) # 128 -> 2128

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 29)
    assert nv.spi_select.value == 1

    await expect_read(nv, 2128)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionBGE(x0, x1, -400).encode()) # 2128 -> 1728

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 29)
    assert nv.spi_select.value == 1

    await expect_read(nv, 1728)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionBGE(x1, x0, 20).encode())  # 1728
    await send_instr(nv, InstructionBGEU(x1, x0, 2000).encode()) # 1732 -> 3732

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 29)
    assert nv.spi_select.value == 1

    await expect_read(nv, 3732)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionBEQ(x1, x1, -432).encode()) # 3732 -> 3300

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 2)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 29)
    assert nv.spi_select.value == 1

    await expect_read(nv, 3300)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionBNE(x0, x0, 20).encode())  # 3300
    await send_instr(nv, InstructionBNE(x1, x0, -1000).encode()) # 3304 -> 2304

    await send_instr(nv, InstructionNOP().encode())
    assert nv.spi_select.value == 0
    await ClockCycles(nv.clk, 4)
    if nv.is_buffered.value == 1:
        await ClockCycles(nv.clk, 1)
    assert nv.spi_select.value == 1
    await ClockCycles(nv.clk, 27)
    assert nv.spi_select.value == 1

    await expect_read(nv, 2304)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionNOP().encode())
    await send_instr(nv, InstructionNOP().encode())

@cocotb.test()
async def test_store(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionADDI(x1, x0, 279).encode())
    assert await get_reg_value(nv, x1, 8) == 23
    assert await get_reg_value(nv, x1, 16) == 279
    assert await get_reg_value(nv, x1, 32) == 279
    await send_instr(nv, InstructionAUIPC(x2, 1025).encode())
    assert await get_reg_value(nv, x2, 8) == 16
    assert await get_reg_value(nv, x2, 16) == (1 << 12) + 16
    assert await get_reg_value(nv, x2, 32) == (1025 << 12) + 16

@cocotb.test()
async def test_load(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await load_reg(nv, x1, 123456789)
    assert await get_reg_value(nv, x1) == 123456789
    await load_reg(nv, x1, -42, 16, True)
    assert await get_reg_value(nv, x1) == (-42) & 0xFFFFFFFF
    await load_reg(nv, x2, -42, 16, False)
    assert await get_reg_value(nv, x2) == (-42) & 0xFFFF
    await load_reg(nv, x5, -42, 8, True)
    assert await get_reg_value(nv, x5) == (-42) & 0xFFFFFFFF
    await load_reg(nv, x6, -42, 8, False)
    assert await get_reg_value(nv, x6) == (-42) & 0xFF
    await load_reg(nv, x1, 123456789, 8, False)
    assert await get_reg_value(nv, x1) == 123456789 & 0xFF

    if nv.is_buffered.value == 0:
        await load_reg(nv, x1, 123456789, 32, False, True)
        assert await get_reg_value(nv, x1) == 123456789

@cocotb.test()
async def test_slt(nv):
    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)

    await send_instr(nv, InstructionADDI(x1, x0, 1).encode())
    await send_instr(nv, InstructionSLTI(x2, x1, 0).encode())
    await send_instr(nv, InstructionSLTI(x5, x1, 2).encode())
    assert await get_reg_value(nv, x2) == 0
    assert await get_reg_value(nv, x5) == 1

    await send_instr(nv, InstructionADDI(x1, x0, -1).encode())
    await send_instr(nv, InstructionADDI(x6, x0, -2).encode())
    await send_instr(nv, InstructionSLT(x2, x1, x0).encode())
    await send_instr(nv, InstructionSLT(x5, x1, x6).encode())
    assert await get_reg_value(nv, x2) == 1
    assert await get_reg_value(nv, x5) == 0

@cocotb.test()
async def test_fast_store(nv):
    global pc

    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)
    else:
        return

    addr = random.randint(0, 255) * 4
    addr2 = random.randint(0, 255) * 4
    await send_instr(nv, InstructionADDI(x1, x0, 279).encode())
    await send_instr(nv, InstructionADDI(x2, x0, -523).encode())
    await send_instr(nv, InstructionSW(x4, x1, addr).encode())

    instr = InstructionSW(x4, x2, addr2).encode()

    pc += 4
    await Timer(1, "ns")
    nv.spi_data_in.value = instr & 1

    assert nv.store_addr_out.value == 1
    assert nv.store_data_out.value == 0
    assert nv.addr_out.value == 0x10000000 + addr

    await ClockCycles(nv.clk, 1)
    await Timer(1, "ns")    

    for i in range(1, 31):
        nv.spi_data_in.value = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
        await Timer(1, "ns")    
        assert nv.store_addr_out.value == 0
        assert nv.store_data_out.value == 0

    nv.spi_data_in.value = (instr >> 31) & 1
    await ClockCycles(nv.clk, 1)
    await Timer(1, "ns")    
    assert nv.store_addr_out.value == 1
    assert nv.store_data_out.value == 1
    assert nv.data_out.value == 279
    assert nv.addr_out.value == 0x10000000 + addr2

    instr = InstructionADDI(x2, x0, 0).encode()
    pc += 4
    for i in range(0,31):
        nv.spi_data_in.value = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
        await Timer(1, "ns")    
        assert nv.store_addr_out.value == 0
        assert nv.store_data_out.value == 0

    nv.spi_data_in.value = (instr >> 31) & 1
    await ClockCycles(nv.clk, 1)
    await Timer(1, "ns")    
    assert nv.store_addr_out.value == 0
    assert nv.store_data_out.value == 1
    assert nv.data_out.value == -523 & 0xFFFFFFFF

@cocotb.test()
async def test_fast_load(nv):
    global pc

    await do_start(nv)
    await expect_read(nv, 0)

    if nv.is_buffered.value == 0:
        await ClockCycles(nv.clk, 1)
    else:
        return

    addr = random.randint(0, 255) * 4
    await send_instr(nv, InstructionLW(x2, x4, addr).encode())

    instr = InstructionADDI(x1, x0, 279).encode()
    assert nv.store_addr_out.value == 1
    assert nv.data_in_read.value == 0
    assert nv.addr_out.value == 0x10000000 + addr

    pc += 4
    await Timer(1, "ns")
    nv.ext_data_in.value = 0x12345678

    for i in range(31):
        nv.spi_data_in.value = (instr >> i) & 1
        await ClockCycles(nv.clk, 1)
        await Timer(1, "ns")    
        assert nv.store_addr_out.value == 0
        assert nv.data_in_read.value == 0

    nv.spi_data_in.value = (instr >> 31) & 1
    await ClockCycles(nv.clk, 1)
    await Timer(1, "ns")    
    assert nv.store_addr_out.value == 0
    assert nv.data_in_read.value == 1

    assert await get_reg_value(nv, x2) == 0x12345678

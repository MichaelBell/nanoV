import random

import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_add(alu):
    alu.op.value = 0b000

    for i in range(100):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (a + b) & 0xFFFFFFFF

@cocotb.test()
async def test_slt(alu):
    alu.op.value = 0b010

    alu.a.value = 1
    alu.b.value = 1
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = 0
    await Timer(1)
    assert alu.d.value == 1

    alu.a.value = -1
    alu.b.value = -1
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = -2
    await Timer(1)
    assert alu.d.value == 1

    alu.a.value = 0
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = 0
    alu.b.value = 0
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = -1
    await Timer(1)
    assert alu.d.value == 1

    for i in range(100):
        a = random.randint(-0x80000000, 0x7FFFFFFF)
        b = random.randint(-0x80000000, 0x7FFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (1 if (a < b) else 0)

@cocotb.test()
async def test_sltu(alu):
    alu.op.value = 0b011

    alu.a.value = 1
    alu.b.value = 1
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = 0
    await Timer(1)
    assert alu.d.value == 1

    alu.a.value = -1
    alu.b.value = -1
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = -2
    await Timer(1)
    assert alu.d.value == 1

    alu.a.value = 0
    await Timer(1)
    assert alu.d.value == 1

    alu.a.value = 0
    alu.b.value = 0
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = -1
    await Timer(1)
    assert alu.d.value == 0

    alu.a.value = 1
    await Timer(1)
    assert alu.d.value == 0

    for i in range(100):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (1 if (a < b) else 0)

@cocotb.test()
async def test_and(alu):
    alu.op.value = 0b111

    for i in range(100):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (a & b) & 0xFFFFFFFF

@cocotb.test()
async def test_or(alu):
    alu.op.value = 0b110

    for i in range(100):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (a | b) & 0xFFFFFFFF

@cocotb.test()
async def test_xor(alu):
    alu.op.value = 0b100

    for i in range(100):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        alu.a.value = a
        alu.b.value = b

        await Timer(1)
        assert alu.d.value == (a ^ b) & 0xFFFFFFFF


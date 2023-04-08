import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

from riscvmodel.insn import *
from riscvmodel.regnames import x0, x1, x2

@cocotb.test()
async def test_add(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 32)

    nv.instr.value = InstructionADDI(x1, x0, 279).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADDI(x2, x1, 3).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 279
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionADDI(x1, x0, 2).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 282
    await ClockCycles(nv.clk, 31)

    nv.instr.value = InstructionSW(x0, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADD(x2, x1, x1).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 2
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADD(x2, x2, x1).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 4
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADDI(x1, x2, 1).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 6
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionSW(x0, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADDI(x1, x2, 1).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 7

@cocotb.test()
async def test_slt(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 32)

    nv.instr.value = InstructionADDI(x1, x0, 1).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSLTI(x2, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 33)
    assert nv.data_out.value == 0
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionSLTI(x2, x1, 2).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 33)
    assert nv.data_out.value == 1
    await ClockCycles(nv.clk, 31)


reg = [0] * 16

# Each Op does reg[d] = fn(a, b)
# fn will access reg global array
class Op:
    def __init__(self, rvm_insn, fn, name):
        self.rvm_insn = rvm_insn
        self.fn = fn
        self.name = name
    
    def execute_fn(self, rd, rs1, arg2):
        if rd != 0:
            reg[rd] = self.fn(rs1, arg2)
            if  reg[rd] < -0x80000000: reg[rd] += 0x100000000
            elif reg[rd] > 0x7FFFFFFF:  reg[rd] -= 0x100000000

    def encode(self, rd, rs1, arg2):
        return self.rvm_insn(rd, rs1, arg2).encode()

ops = [
    Op(InstructionADDI, lambda rs1, imm: reg[rs1] + imm, "+i"),
    Op(InstructionADD, lambda rs1, rs2: reg[rs1] + reg[rs2], "+"),
    Op(InstructionSUB, lambda rs1, rs2: reg[rs1] - reg[rs2], "-"),
    Op(InstructionANDI, lambda rs1, imm: reg[rs1] & imm, "&i"),
    Op(InstructionAND, lambda rs1, rs2: reg[rs1] & reg[rs2], "&"),
    Op(InstructionORI, lambda rs1, imm: reg[rs1] | imm, "|i"),
    Op(InstructionOR, lambda rs1, rs2: reg[rs1] | reg[rs2], "|"),
    Op(InstructionXORI, lambda rs1, imm: reg[rs1] ^ imm, "^i"),
    Op(InstructionXOR, lambda rs1, rs2: reg[rs1] ^ reg[rs2], "^"),
]

@cocotb.test()
async def test_random(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    await ClockCycles(nv.clk, 32)

    seed = random.randint(0, 0xFFFFFFFF)
    for test in range(100):
        random.seed(seed + test)
        nv._log.info("Running test with seed {}".format(seed + test))
        for i in range(1, 16):
            reg[i] = random.randint(-2048, 2047)
            #print("Set reg {} to {}".format(i, reg[i]))
            nv.instr.value = InstructionADDI(i, x0, reg[i]).encode()
            await ClockCycles(nv.clk, 32)

        if True:
            nv.instr.value = InstructionSW(x0, 0, 0).encode()
            await ClockCycles(nv.clk, 1)
            for i in range(16):
                await ClockCycles(nv.clk, 31)

                nv.instr.value = InstructionSW(x0, (i+1) & 0xF, 0).encode()
                await ClockCycles(nv.clk, 1)
                #print("Reg {} is {}".format(i, nv.data_out.value.signed_integer))
                assert nv.data_out.value.signed_integer == reg[i]
            await ClockCycles(nv.clk, 31)

        for i in range(25):
            instr = random.choice(ops)
            rd = random.randint(0, 15)
            rs1 = random.randint(0, 15)
            arg2 = random.randint(0, 15)  # TODO

            nv.instr.value = instr.encode(rd, rs1, arg2)
            instr.execute_fn(rd, rs1, arg2)
            #print("x{} = x{} {} {}, now {}".format(rd, rs1, arg2, instr.name, reg[rd]))
            await ClockCycles(nv.clk, 32)

        nv.instr.value = InstructionSW(x0, 0, 0).encode()
        await ClockCycles(nv.clk, 1)
        for i in range(16):
            await ClockCycles(nv.clk, 31)

            nv.instr.value = InstructionSW(x0, (i+1) & 0xF, 0).encode()
            await ClockCycles(nv.clk, 1)
            #print("Reg x{} = {} should be {}".format(i, int(nv.data_out.value), reg[i]))
            assert nv.data_out.value == reg[i] & 0xFFFFFFFF
        await ClockCycles(nv.clk, 31)

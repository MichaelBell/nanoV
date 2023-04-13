import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

from riscvmodel.insn import *
from riscvmodel.regnames import x0, x1, x2, x3

@cocotb.test()
async def test_add(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.instr.value = InstructionNOP().encode()
    nv.cycle.value = 0
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

async def get_reg_value(nv, reg):
    nv.instr.value = InstructionSW(x0, reg, 0).encode()
    await ClockCycles(nv.clk, 33)
    val = nv.data_out.value
    await ClockCycles(nv.clk, 31)
    return val

@cocotb.test()
async def test_lui(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.instr.value = InstructionNOP().encode()
    nv.cycle.value = 0
    await ClockCycles(nv.clk, 32)

    nv.instr.value = InstructionLUI(x1, 279).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionADDI(x2, x1, 3).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == 279 << 12
    await ClockCycles(nv.clk, 31)
    nv.instr.value = InstructionADDI(x1, x0, 2).encode()
    await ClockCycles(nv.clk, 1)
    assert nv.data_out.value == (279 << 12) + 3
    await ClockCycles(nv.clk, 31)

@cocotb.test()
async def test_slt(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.cycle.value = 0
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 32)

    nv.instr.value = InstructionADDI(x1, x0, 1).encode()
    await ClockCycles(nv.clk, 32)
    nv.next_instr.value = InstructionSLTI(x2, x1, 2).encode()
    nv.instr.value = InstructionSLTI(x2, x1, 0).encode()
    await ClockCycles(nv.clk, 32)
    assert await get_reg_value(nv, x2) == 0

    nv.instr.value = nv.next_instr.value
    nv.next_instr.value = InstructionSW(x0, x2, 0).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = nv.next_instr.value
    assert await get_reg_value(nv, x2) == 1

async def TwoCycleInstr(nv):
    nv.cycle.value = 0
    await ClockCycles(nv.clk, 32)
    nv.cycle.value = 1
    await ClockCycles(nv.clk, 32)
    nv.cycle.value = 0

@cocotb.test()
async def test_shift(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    nv.cycle.value = 0
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 32)

    nv.instr.value = InstructionADDI(x1, x0, 1).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSLLI(x2, x1, 4).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 16
    nv.instr.value = InstructionSLLI(x2, x1, 2).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 4
    nv.instr.value = InstructionSLLI(x2, x1, 0).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 1
    nv.instr.value = InstructionSLLI(x2, x1, 31).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0x80000000

    nv.instr.value = InstructionADDI(x3, x0, 1).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSLL(x2, x1, x3).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 2
    nv.instr.value = InstructionADDI(x3, x3, 15).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSLL(x3, x1, x3).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x3) == 0x10000

    nv.instr.value = InstructionSRLI(x2, x3, 1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0x8000
    nv.instr.value = InstructionSRLI(x2, x3, 4).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0x1000

    nv.instr.value = InstructionSRL(x2, x3, x1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0x8000
    nv.instr.value = InstructionADDI(x1, x0, 15).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSRL(x2, x3, x1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 2
    nv.instr.value = InstructionADDI(x1, x0, 17).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSRL(x2, x3, x1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0

    nv.instr.value = InstructionSRAI(x2, x3, 15).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 2

    nv.instr.value = InstructionSLLI(x3, x3, 15).encode()
    await TwoCycleInstr(nv)

    nv.instr.value = InstructionSRAI(x2, x3, 1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0xC0000000
    nv.instr.value = InstructionADDI(x1, x0, 15).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSRA(x2, x3, x1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0xFFFF0000
    nv.instr.value = InstructionADDI(x1, x0, 17).encode()
    await ClockCycles(nv.clk, 32)
    nv.instr.value = InstructionSRA(x2, x3, x1).encode()
    await TwoCycleInstr(nv)
    assert await get_reg_value(nv, x2) == 0xFFFFC000


reg = [0] * 16

# Each Op does reg[d] = fn(a, b)
# fn will access reg global array
class Op:
    def __init__(self, rvm_insn, fn, cycles, name):
        self.rvm_insn = rvm_insn
        self.fn = fn
        self.name = name
        self.cycles = cycles
    
    def execute_fn(self, rd, rs1, arg2):
        if rd != 0:
            reg[rd] = self.fn(rs1, arg2)
            while reg[rd] < -0x80000000: reg[rd] += 0x100000000
            while reg[rd] > 0x7FFFFFFF:  reg[rd] -= 0x100000000

    def encode(self, rd, rs1, arg2):
        return self.rvm_insn(rd, rs1, arg2).encode()

ops = [
    Op(InstructionADDI, lambda rs1, imm: reg[rs1] + imm, 1, "+i"),
    Op(InstructionADD, lambda rs1, rs2: reg[rs1] + reg[rs2], 1, "+"),
    Op(InstructionSUB, lambda rs1, rs2: reg[rs1] - reg[rs2], 1, "-"),
    Op(InstructionANDI, lambda rs1, imm: reg[rs1] & imm, 1, "&i"),
    Op(InstructionAND, lambda rs1, rs2: reg[rs1] & reg[rs2], 1, "&"),
    Op(InstructionORI, lambda rs1, imm: reg[rs1] | imm, 1, "|i"),
    Op(InstructionOR, lambda rs1, rs2: reg[rs1] | reg[rs2], 1, "|"),
    Op(InstructionXORI, lambda rs1, imm: reg[rs1] ^ imm, 1, "^i"),
    Op(InstructionXOR, lambda rs1, rs2: reg[rs1] ^ reg[rs2], 1, "^"),
    Op(InstructionSLTI, lambda rs1, imm: 1 if reg[rs1] < imm else 0, 1, "<i"),
    Op(InstructionSLT, lambda rs1, rs2: 1 if reg[rs1] < reg[rs2] else 0, 1, "<"),
    Op(InstructionSLTIU, lambda rs1, imm: 1 if (reg[rs1] & 0xFFFFFFFF) < (imm & 0xFFFFFFFF) else 0, 1, "<iu"),
    Op(InstructionSLTU, lambda rs1, rs2: 1 if (reg[rs1] & 0xFFFFFFFF) < (reg[rs2] & 0xFFFFFFFF) else 0, 1, "<u"),
    Op(InstructionSLLI, lambda rs1, imm: reg[rs1] << imm, 2, "<<i"),
    Op(InstructionSLL, lambda rs1, rs2: reg[rs1] << (reg[rs2] & 0x1F), 2, "<<"),
    Op(InstructionSRLI, lambda rs1, imm: (reg[rs1] & 0xFFFFFFFF) >> imm, 2, ">>li"),
    Op(InstructionSRL, lambda rs1, rs2: (reg[rs1] & 0xFFFFFFFF) >> (reg[rs2] & 0x1F), 2, ">>l"),
    Op(InstructionSRAI, lambda rs1, imm: reg[rs1] >> imm, 2, ">>i"),
    Op(InstructionSRA, lambda rs1, rs2: reg[rs1] >> (reg[rs2] & 0x1F), 2, ">>"),
]

@cocotb.test()
async def test_random(nv):
    clock = Clock(nv.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    nv.cycle.value = 0
    nv.instr.value = InstructionNOP().encode()
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    await ClockCycles(nv.clk, 32)

    seed = random.randint(0, 0xFFFFFFFF)
    #seed = 892186356
    debug = False
    for test in range(100):
        random.seed(seed + test)
        nv._log.info("Running test with seed {}".format(seed + test))
        nv.next_instr.value = InstructionNOP().encode()
        for i in range(1, 16):
            reg[i] = random.randint(-2048, 2047)
            if debug: print("Set reg {} to {}".format(i, reg[i]))
            nv.instr.value = InstructionADDI(i, x0, reg[i]).encode()
            await ClockCycles(nv.clk, 32)

        if True:
            nv.instr.value = InstructionSW(x0, 0, 0).encode()
            await ClockCycles(nv.clk, 1)
            for i in range(16):
                await ClockCycles(nv.clk, 31)

                nv.instr.value = InstructionSW(x0, (i+1) & 0xF, 0).encode()
                await ClockCycles(nv.clk, 1)
                if debug: print("Reg {} is {}".format(i, nv.data_out.value.signed_integer))
                assert nv.data_out.value.signed_integer == reg[i]
            await ClockCycles(nv.clk, 31)

        last_instr = ops[0]
        for i in range(25):
            while True:
                try:
                    instr = random.choice(ops)
                    rd = random.randint(0, 15)
                    rs1 = random.randint(0, 15)
                    arg2 = random.randint(0, 15)  # TODO

                    instr.execute_fn(rd, rs1, arg2)
                    break
                except ValueError:
                    pass

            nv.instr.value = nv.next_instr.value
            nv.next_instr.value = instr.encode(rd, rs1, arg2)
            if debug: print("x{} = x{} {} {}, now {} {:08x}".format(rd, rs1, arg2, instr.name, reg[rd], instr.encode(rd, rs1, arg2)))
            for i in range(last_instr.cycles):
                nv.cycle.value = i
                await ClockCycles(nv.clk, 32)
            nv.cycle.value = 0
            last_instr = instr
            #if debug:
            #    assert await get_reg_value(nv, rd) == reg[rd] & 0xFFFFFFFF

        nv.instr.value = nv.next_instr.value
        nv.next_instr.value = InstructionNOP().encode()
        for i in range(last_instr.cycles):
            nv.cycle.value = i
            await ClockCycles(nv.clk, 32)
        nv.cycle.value = 0

        nv.instr.value = InstructionSW(x0, 0, 0).encode()
        await ClockCycles(nv.clk, 1)
        for i in range(16):
            await ClockCycles(nv.clk, 31)

            nv.instr.value = InstructionSW(x0, (i+1) & 0xF, 0).encode()
            await ClockCycles(nv.clk, 1)
            if debug: print("Reg x{} = {} should be {}".format(i, int(nv.data_out.value), reg[i]))
            assert nv.data_out.value == reg[i] & 0xFFFFFFFF
        await ClockCycles(nv.clk, 31)

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

# Just executes whatever is in test.mem so you can inspect the waveform
# https://riscvasm.lucasteske.dev/# is useful for assembling hex for the file.
@cocotb.test()
async def test_start(nv):
    clock = Clock(nv.clk, 83, units="ns")
    cocotb.start_soon(clock.start())
    nv.rstn.value = 0
    nv.uart_rxd.value = 1
    await ClockCycles(nv.clk, 2)
    nv.rstn.value = 1
    await Timer(1, "us")

    nv.uart_rxd.value = 0
    await Timer(8680, "ns")

    # Send 0x5A
    await Timer(8680, "ns")
    nv.uart_rxd.value = 1
    await Timer(8680, "ns")
    nv.uart_rxd.value = 0
    await Timer(8680, "ns")
    nv.uart_rxd.value = 1
    await Timer(8680, "ns")
    await Timer(8680, "ns")
    nv.uart_rxd.value = 0
    await Timer(8680, "ns")
    nv.uart_rxd.value = 1
    await Timer(8680, "ns")
    nv.uart_rxd.value = 0
    await Timer(8680, "ns")
    nv.uart_rxd.value = 1
    await Timer(8680, "ns")

    await Timer(10, "us")
    
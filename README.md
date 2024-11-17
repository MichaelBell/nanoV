# NanoV: Minimal area RISC-V core and accessories

A bit serial RISC-V core and integrated SPI memory controller, for minimal area RISC-V computing.

## Overview

This RISC-V core is designed to provide a minimal system on chip based on RISC-V and an external FRAM (or similar).

The design was taped out on Tiny Tapeout 4, and the design is guided by minimising area.  It is really more of a curiosity than of practical use - on ASIC normally you would also care about power consumption, and on FPGA the availability of small RAMs would suggest storing the register file in RAM instead of flops.

As well as Tiny Tapeout 4, the design works with [pico-ice](https://tinyvision.ai/products/pico-ice-fpga-trainer-board) and on [iceFUN dev board](https://www.robot-electronics.co.uk/icefun.html).  It is designed to be used with this [FRAM](https://www.adafruit.com/product/4719) - [datasheet](https://cdn-shop.adafruit.com/product-files/4719/4719_MB85RS4MT.pdf).

The advantage of using FRAM is a program can be stored persistently, and the same memory used for RAM.  The FRAM also allows endless reading without any issues with crossing page boundaries or maximum read times, as can be the case with a PSRAM.

The chip in question doesn't mention any restrictions on clock speed for command 03h reads, so they ought to work up to 40MHz.  However due to signla integrity issues I never got 40MHz on the iceFUN, and on Tiny Tapeout the design of the SPI controller, combined with the mux latency meant that the maximum clock speed was around 18MHz.

As the design was always intended to be submitted to Tiny Tapeout, where minimizing area is paramount, a significant design consideration was to minimize the number and complexity of DFFs used as on ASIC DFFs are generally more expensive than combinational logic.

## Processor description

Inspired by Luke Wren's [Whisk 16](https://github.com/Wren6991/tt02-whisk-serial-processor) submission for Tiny Tapeout 2, this processor is bit serial and the general purpose registers can be implemented as a ring of DFFs that rotate every clock - no exceptions.  Only 2 bits of each 32-bit register can be accessed.  These rules minimize the complexity of the register flip flops, minimizing area.

The processor executes simple instructions in "1 cycle", each cycle is 32 clocks long.  While the instruction is executed the next instruction is read over SPI.  For multi-cycle instructions that don't access memory, the SPI clock is gated once the next instruction is read until the executing instruction is complete.

For jumps and conditional branches, the SPI memory access must be interrupted.  For jumps the SPI is deselected on the second clock of the cycle, for conditional branches it is only deselected on the first clock of the second cycle if the branch is taken.  If the branch is not taken then instructions continue executing uninterrupted.

For loads and stores the SPI memory access must be interrupted, the data access completed, and then the instruction access resumed.

The PC is 22 bits internally, allowing programs to sit in the bottom 4MB of the connected RAM.  SPI addresses are 24-bit, so up to 16MB of data can be addressed.

Peripherals are accessed at adresses around 0x10000000, currently this consists of GPIO and a very simple UART.  Peripheral loads and stores take 1 cycle, providing they use an offset against the hardwired value of tp for addressing.

Instructions implemented are:
- All of RV32E except FENCE, EBREAK and ECALL.
- MUL from RV32M performs a 32-bit by 16-bit multiply (only the bottom 16-bits of rs2 are used), allowing a full 32x32 multiply to be implemented easily in software.

Registers gp (x3) and tp (x4) have hardwired values, as the standard ABI doesn't modify them.  gp is set to 0x1000, allowing cheap loads and stores to the bottom 6KB of RAM by offsetting against x0 for the first 2KB and gp for the next 4KB.  tp is set to 0x10000000 for quick access to the peripherals.

## Instruction timing

Current instruction timing is as follows (each cycle is 32 clocks):

| Instruction | Cycles |
|-------------|--------|
| AND/OR/XOR  | 1      |
| ADD/SUB     | 1      |
| LUI/AUIPC   | 1      |
| SLT         | 1      |
| Shifts      | 2      |
| Mul (32x16) | 2      |
| JAL/JALR    | 3      |
| Branch (not taken) | 1 |
| Branch (taken) | 4   |
| Store       | 5      |
| Load        | 5      |

## Results and later work

This SoC worked on Tiny Tapeout 4, possibly it was the first full Risc-V SoC to be taped out on Tiny Tapeout?  I was able to verify a variety of simple programs, including my [Advent of Code 2023](https://github.com/MichaelBell/AoC-2023) projects and several of Bruno Levy's [Tiny Programs](https://github.com/BrunoLevy/TinyPrograms).  I was also able to get a version of [MicroPython](https://github.com/MichaelBell/micropython/tree/nanoV) running, but the 512kB limit of the FRAM meant there was almost no usable RAM for programs.

I'm unlikely to develop this project further as my efforts are now focussed on [TinyQV](https://github.com/MichaelBell/tinyQV), which works is 4-bit serial using QSPI PSRAM and flash, allowing 4 or more times higher throughput.  TinyQV was taped out on TT06.

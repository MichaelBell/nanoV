# NanoV: Minimal area RISC-V core and accessories

A bit serial RISC-V core and integrated SPI memory controller, for minimal area RISC-V computing.

## Overview

This RISC-V core is designed to provide a minimal system on chip based on RISC-V and an external FRAM (or similar).

Currently under development, the first target is to get this running on the [iceFUN dev board](https://www.robot-electronics.co.uk/icefun.html) and this [FRAM](https://www.adafruit.com/product/4719) - [datasheet](https://cdn-shop.adafruit.com/product-files/4719/4719_MB85RS4MT.pdf).

The advantage of using FRAM is a program can be stored persistently, and the same memory used for RAM.  The FRAM also (appears to - I havent tested this yet!) allow endless reading without any issues with crossing page boundaries or maximum read times, as can be the case with a PSRAM.  The HOLD pin also looks useful for interrupting instruction read for multi-cycle instructions without having to issue a new command (though stopping the clock may also work).

The chip in question doesn't mention any restrictions on clock speed for command 03h reads, so they ought to work up to 40MHz.  Therefore running on ICE40 HX8k at 40MHz is the initial goal.

The eventual goal is to submit this design to a Tiny Tapeout on ASIC, where minimizing area is paramount.  Therefore a significant design consideration is to minimize the number and complexity of DFFs used as on ASIC DFFs are generally more expensive than combinational logic.

## Processor description

Inspired by Luke Wren's [Whisk 16](https://github.com/Wren6991/tt02-whisk-serial-processor) submission for Tiny Tapeout 2, this processor is bit serial and the general purpose registers can be implemented as a ring of DFFs that rotate every clock - no exceptions.  Only 2 bits of each 32-bit register can be accessed.  These rules minimize the complexity of the register flip flops, minimizing area.

On FPGA, the 30 inaccessible bits of the registers are stored in a BRAM which is used as a FIFO.

The processor executes simple instructions in "1 cycle", each cycle is 32 clocks long.  While the instruction is executed the next instruction is read over SPI.  For multi-cycle instructions that don't access memory, the SPI clock is gated once the next instruction is read until the executing instruction is complete.

For jumps and conditional branches, the SPI memory access must be interrupted.  For jumps the SPI is deselected on the second clock of the cycle, for conditional branches it is only deselected on the first clock of the second cycle if the branch is taken.  If the branch is not taken then instructions continue executing uninterrupted.

For loads and stores (not yet implemented) the SPI memory access must be interrupted, the data access completed, and then the instruction access resumed.

The PC is 22 bits internally, allowing programs to sit in the bottom 4MB of the connected RAM.  SPI addresses are 24-bit, so up to 16MB of data can be addressed.

I intend to add GPIO access using addresses above the first 16MB, which should allow for bit-banged UART.  In future I may add more peripherals.

## Instruction timing

Current instruction timing is as follows:

| Instruction | Cycles |
|-------------|--------|
| AND/OR/XOR  | 1      |
| ADD/SUB     | 1      |
| LUI/AUIPC   | 1      |
| SLT         | 1      |
| Shifts      | 2      |
| JAL/JALR    | 3      |
| Branch (not taken) | 1 |
| Branch (taken) | 4   |
| Store (not yet implemented) | 5 |
| Load (not yet implemented) | 5 |

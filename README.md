# Simple RISC-V Single-Cycle CPU

This project implements a basic single-cycle CPU capable of executing 37 RISC-V instructions. The CPU supports all RV32I base integer instructions.

## Features

- Implements a single-cycle CPU architecture
- Supports 37 RISC-V RV32I instructions
- Designed for educational and experimental purposes
- Synthesizable and tested on FPGA

## Instruction Set

All supported RV32I instructions are shown in the following image:

![RV32I Instructions](/Image/riscv.png)

## FPGA Operation

To operate on an FPGA board, you should
The CPU has been synthesized and successfully run on an FPGA board. The operation results are shown below:

![FPGA Operation Result](/Image/operation.png)

## Getting Started

1. Clone this repository.
2. Download and install [Vivado 2023.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2023-2.html).
3. Synthesize the design using your preferred FPGA toolchain.
4. Load the bitstream onto your FPGA board.
5. Observe the operation results as shown above.

## License

This project is for educational use only.
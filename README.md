# ManabiSystolicArray (Verilog HDL, Google DSLX, C++, Python)

## Introduction

A circuit architecture known as a **systolic array** reduces the data-transfer volume of weight matrices in neural-network matrix computations. In this project, we will design a systolic array purely for the purpose of self-learning and experimentation.  
> *This project is for educational and experimental purposes. Production-grade features and performance optimizations will be addressed in future work.*

## Objective

A **systolic array** is an array of processing elements (PEs) arranged to perform matrix multiplication efficiently. It is employed in AI accelerator chips and NPUs by major IT companies. Here, we will undertake a hobbyist-level implementation.

## Block Diagrams

- **Conceptual diagram of a systolic array**  
  ![Systolic Array](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true)

- **Implementation with control logic added**  
  *(RISC-V is used here solely as a learning exercise.)*  
  ![Implementation Example](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu2.jpg?raw=true)

## Designed Artifacts

- **Python model**  
- **Systolic-array design data** (Verilog)  
- **RISC-V core design data** (Verilog)  
- **RISC-V host program** (C++)  
- **FPGA integration data** (Verilog)  
- **16-bit floating-point multiplier** (DSLX → Verilog)

## Demo Results

1. Compiled the C++ host program  
2. Converted the executable to a `.hex` file  
3. Successfully ran a cocotb simulation

## Design Details

1. **Python model**  
   - File: `Python_model/SystolicArray_model.py`  
   - Defines class `PE` for each processing element, modeling right-shift and down-shift operations.

2. **Systolic-array design (Verilog)**  
   - Directory: `Verilog/SA4x4/`  
   - Direct Verilog implementation of the Python model.  
   - An 8×8 variant exists but has not yet been tested.

3. **RISC-V core design (Verilog)**  
   - Directory: `Verilog/RISCV/`  
     1. `RV32IM_FPGA_PIPELINE.v` — a classic 5-stage pipeline  
     2. `RV32IM_FPGA_PIPELINE_SUP.v` — as deeply pipelined as possible

4. **RISC-V host program (C++)**  
   - Directory: `c_program/`  
   - Requires installation of the RISC-V toolchain to build.  
   - Filenames will be renamed to more descriptive ones later.

5. **FPGA integration data (Verilog)**  
   - Directory: `fpga/`  
   - Only synthesis has been tested so far; the 4×4 array synthesizes successfully.

6. **16-bit floating-point multiplier (DSLX → Verilog)**  
   - Directory: `Verilog/fp16_mul/`  
     - `fp16_mul.x`: the DSLX source  
     - `fp16_multiplier_stage_n.v`: the generated Verilog for pipeline stage count `n`  
   - Design complete but not yet integrated into the main project.

## Unresolved Issues

- No built-in support for floating-point operations within the systolic array itself  
- Synthesizing an 8×8 array on FPGA is currently impractical

## Remarks

This document consolidates notes from several months ago, recorded before I forget.  
*(Again, this project is for learning purposes only and is unrelated to my professional work.)*  

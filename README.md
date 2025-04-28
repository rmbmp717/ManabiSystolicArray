# ManabiSystollicArray (Verilog HDL · Google DSLX · C++ · Python)

## Introduction
A **systolic array** is a circuit architecture that reduces the amount of weight-matrix data that must be moved during neural-network computations.  
This repository contains a hobby-level implementation built for self-learning and experimentation.

> *This project is for educational and experimental purposes only. Production-grade features and performance optimizations will be handled later.*

---

## Objective
A systolic array consists of many processing elements (PEs) arranged so that matrix-multiplication data flows from one PE to the next in a pipelined fashion, enabling very high throughput.  
Such arrays appear in AI accelerators and NPUs from major tech companies; here we implement one as a personal project.

---

## Block Diagrams
| | |
|---|---|
| **Conceptual view** | **Practical implementation (with control logic)**<br>*RISC-V is used purely as a design exercise.* |
| <img src="https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true" alt="Conceptual Array" width="300"/> | <img src="https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu2.jpg?raw=true" alt="Practical Array" width="300"/> |

---

## Designed Artifacts
- **Python model**
- **Systolic-array design data** (Verilog)
- **RISC-V core design data** (Verilog)
- **RISC-V host program** (C++)
- **FPGA integration data** (Verilog)
- **16-bit floating-point multiplier** (DSLX → Verilog)

---

## Demo Results
1. Compile the C++ host program.  
2. Convert the executable into a `.hex` image.  
3. Run a **cocotb** simulation.

### Command-line Output
```bash
1450.00ns INFO  cocotb  C_tmp = [  0   0   0 114]
1450.00ns INFO  cocotb  Updated HW result during step row_i=6 =
                       [[181  78  97  90]
                        [ 84 103  72  33]
                        [114  36  80  79]
                        [212 110 136 114]]
=============== calc loop end ===============
=============== Output data ================
1650.00ns INFO  cocotb  Updated HW result during step row_i=6 =
                       [[181  78  97  90]
                        [ 84 103  72  33]
                        [114  36  80  79]
                        [212 110 136 114]]
1650.00ns INFO  cocotb  Test Passed! HW result matches Python model.
1650.00ns INFO  cocotb.regression  test_systolic_array passed
```

---

## Simulation Waveform
The waveform also confirms that the hardware result matches the Python reference.  
![Simulation Waveform](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_wave.jpg?raw=true)

---

## Design Details
1. **Python model**  
   `Python_model/SystolicArray_model.py` — class **PE** models right-shift & down-shift links.

2. **Systolic array RTL (Verilog)**  
   `Verilog/SA4x4/` — direct transcription of the Python model.  
   An 8 × 8 version exists but is still unverified.

3. **RISC-V cores (Verilog)**  
   `Verilog/RISCV/`  
   - `RV32IM_FPGA_PIPELINE.v` — classic 5-stage pipeline  
   - `RV32IM_FPGA_PIPELINE_SUP.v` — deeply pipelined variant

4. **Host program (C++)**  
   `c_program/` — build with any standard RISC-V GCC toolchain.  
   File names will be made more descriptive later.

5. **FPGA top-level**  
   `fpga/` — synthesis tested; the 4 × 4 array meets timing on mid-range FPGAs.

6. **16-bit FP multiplier (DSLX → Verilog)**  
   `Verilog/fp16_mul/`  
   - `fp16_mul.x` — DSLX source  
   - `fp16_multiplier_stage_n.v` — generated Verilog, pipeline depth *n*  
   Not yet integrated into the main datapath.

---

## Unresolved Issues
- The systolic array currently supports only integer operations.  
- Synthesizing an 8 × 8 array on the target FPGA is impractical at present.

---

## Summary
This README consolidates notes recorded over several months to preserve progress.  
**Development time so far:** ~20 hours (2 h × 10 days)

> *Again, this is a personal learning project and is not related to my professional work.*

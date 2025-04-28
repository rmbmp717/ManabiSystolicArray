# ManabiSystollicArray (Verilog HDL · Google DSLX · C++ · Python)

## Introduction

There is a circuit architecture called a **systolic array** that reduces the data-transfer volume of weight matrices in neural-network matrix computations. In this project, we design a systolic array purely for self-learning and experimentation.  
> *This project is for educational and experimental purposes. Production-grade features and performance optimizations will be addressed in future work.*

## Objective

A **systolic array** is an array of processing elements (PEs) arranged to perform matrix multiplication efficiently. It is employed in AI accelerator chips and NPUs by major IT companies. Here, we undertake a hobby-level build.

## Block Diagrams

- **Conceptual view of a systolic array**  
  ![Systolic Array](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true)

- **Implementation with control logic added**  
  *(RISC-V is used solely as a learning exercise.)*  
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

### Command-line Output

```bash
  1450.00ns INFO     cocotb                             C_tmp = 
                                                        [  0   0   0 114]
  1450.00ns INFO     cocotb                             Updated HW result during step row_i=6 = 
                                                        [[181  78  97  90]
                                                         [ 84 103  72  33]
                                                         [114  36  80  79]
                                                         [212 110 136 114]]
===============calc roop end =======================
=============== Output data =======================
  1650.00ns INFO     cocotb                             Updated HW result during step row_i=6 = 
                                                        [[181  78  97  90]
                                                         [ 84 103  72  33]
                                                         [114  36  80  79]
                                                         [212 110 136 114]]
  1650.00ns INFO     cocotb                             Test Passed! HW result matches Python model.
  1650.00ns INFO     cocotb.regression                  test_systolic_array passed
  1650.00ns INFO     cocotb.regression                  ****************************************************************************************
                                                        ** TEST                            STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        ****************************************************************************************
                                                        ** test_bench.test_systolic_array   PASS        1650.00           0.08      20658.28  **
                                                        ****************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0                 1650.00           0.15      11017.83  **
                                                        ****************************************************************************************

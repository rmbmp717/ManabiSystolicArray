# Makefile

#--------------------------------------------------
# Variables
#--------------------------------------------------

# Variables
TOP = SystolicArray4x4_top
RISCV_FILE = ../RISCV/RV32IM_FPGA_PIPELINE.v
VERILOG_FILE = $(TOP).v SystolicArray4x4.v PE.v shift_module.v data_16x4_module.v $(RISCV_FILE)
COCOTB_FILE = test_SA_riscv
SIM = icarus
COCOTB_DIR = /home/haruhiko/Program/GoogleXLS_test-main/Crc32_Proc/cocotb

# RISC-V ツールチェーン (パスが通っている前提)
CC           = riscv64-unknown-elf-gcc
OBJCOPY      = riscv64-unknown-elf-objcopy

# C ソースファイルやリンカスクリプトなど
C_DIR 		 = ../../c_program
MAIN_C       = $(C_DIR)/SA2.c
LINKER       = linker.ld
ELF          = program.elf
HEX          = program.hex

# CFLAGS: bare-metal ビルド用フラグ
#         -march / -mabi / -nostdlib / -nostartfiles / -lgcc
CFLAGS       = -march=rv32im -mabi=ilp32 -Og -nostdlib -nostartfiles -lgcc

#--------------------------------------------------
# Targets
#--------------------------------------------------
.PHONY: all simulate build-hex clean

# まとめて実行
all: simulate

# 1. C -> ELF, HEX 生成
build-hex: $(MAIN_C) $(LINKER)
	$(CC) $(CFLAGS) -T $(LINKER) -o $(ELF) $(MAIN_C)
	$(OBJCOPY) -O verilog $(ELF) $(HEX)
	@echo "Generated $(HEX) from $(MAIN_C)."

rev_assm:
	riscv64-unknown-elf-objdump -d program.elf 

# Cocotb simulation
simulate: build-hex
	export COCOTB_RESOLVE_X=ZEROS
	iverilog -o sim.vvp -D COCOTB_SIM=1 -g2012 $(VERILOG_FILE)
	MODULE=$(COCOTB_FILE) TOPLEVEL=$(TOP) TOPLEVEL_LANG=verilog \
	SIM=$(SIM) vvp -M $(shell cocotb-config --lib-dir) \
		-m libcocotbvpi_icarus sim.vvp

# Clean intermediate files
clean:
	rm -f sim.vvp
	rm -f *.vcd

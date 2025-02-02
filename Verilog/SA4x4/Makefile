# Variables
TOP = SystolicArray4x4_top
OUTPUT_FILE = $(TOP).v SystolicArray4x4.v PE.v
SIM = icarus
COCOTB_DIR = /home/haruhiko/Program/GoogleXLS_test-main/Crc32_Proc/cocotb

# Cocotb simulation
simulate: 
	iverilog -o sim.vvp -D COCOTB_SIM=1 -g2012 $(OUTPUT_FILE)
	MODULE=test_bench TOPLEVEL=$(TOP) TOPLEVEL_LANG=verilog \
	SIM=$(SIM) vvp -M $(shell cocotb-config --lib-dir) \
		-m libcocotbvpi_icarus sim.vvp

# Clean intermediate files
clean:
	rm -f sim.vvp
	rm -f *.vcd

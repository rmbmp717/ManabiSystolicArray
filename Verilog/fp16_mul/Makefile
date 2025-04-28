# Variables
TOP = fp16_multiplier
INPUT_FILE = fp16_mul.x
IR_FILE = $(TOP).ir
OPT_IR_FILE = $(TOP)_opt.ir
OUTPUT_DIR = /home/haruhiko/xls/bazel-bin
OUTPUT_FILE = fp16_multiplier_stage_5.v

SIM = icarus
COCOTB_DIR = /home/haruhiko/Program/GoogleXLS_test-main/Crc32_Proc/cocotb

# Tools
INTERPRETER = $(OUTPUT_DIR)/xls/dslx/interpreter_main
IR_CONVERTER = $(OUTPUT_DIR)/xls/dslx/ir_convert/ir_converter_main
OPT_MAIN = $(OUTPUT_DIR)/xls/tools/opt_main
CODEGEN_MAIN = $(OUTPUT_DIR)/xls/tools/codegen_main

interpret:
	$(INTERPRETER) --alsologtostderr $(INPUT_FILE)
	#$(INTERPRETER) $(INPUT_FILE)

# Targets with dependencies
ir_convert: interpret
	$(IR_CONVERTER) --top=$(TOP) $(INPUT_FILE) > $(IR_FILE)

optimize: ir_convert
	$(OPT_MAIN) \
	$(IR_FILE) > $(OPT_IR_FILE)

# Verilog コード生成タスク (1〜10 のステージで生成)
codegen: optimize
	mkdir -p $(OUTPUT_DIR)  # 出力ディレクトリを作成
	@for STAGE in 1 2 3 4 5 6 7 8 9 10; do \
		echo "Generating Verilog with pipeline_stages=$$STAGE..."; \
		$(CODEGEN_MAIN) \
		--module_name=$(TOP) \
		--pipeline_stages=$$STAGE \
		--delay_model=unit \
		--use_system_verilog=false \
		$(OPT_IR_FILE) > fp16_multiplier_stage_$$STAGE.v; \
	done

# Add timescale directive (in-place update)
add_timescale: codegen
	cp $(OUTPUT_FILE) $(OUTPUT_FILE).bak
	echo '`timescale 1ns / 1ps' | cat - $(OUTPUT_FILE).bak > $(OUTPUT_FILE)
	rm -f $(OUTPUT_FILE).bak

# Cocotb simulation
simulate: add_timescale
	iverilog -o sim.vvp -D COCOTB_SIM=1 -g2012 $(OUTPUT_FILE) 
	MODULE=fp16_mul_test TOPLEVEL=fp16_multiplier TOPLEVEL_LANG=verilog \
	SIM=$(SIM) vvp -M $(shell cocotb-config --lib-dir) \
		-m libcocotbvpi_icarus sim.vvp

# Cocotb simulation
simulate_v: 
	iverilog -o sim.vvp -D COCOTB_SIM=1 -g2012 fp16_mul.v
	MODULE=fp16_mul_test_v TOPLEVEL=fp16_multiplier TOPLEVEL_LANG=verilog \
	SIM=$(SIM) vvp -M $(shell cocotb-config --lib-dir) \
		-m libcocotbvpi_icarus sim.vvp
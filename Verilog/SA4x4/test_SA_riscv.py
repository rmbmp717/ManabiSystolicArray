import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np

# Python model (simple matrix multiplication)
def python_systolic_model(A, B):
    """
    A, B: NumPy arrays with shape=(4,4)
    Returns: C = A×B (4x4 matrix multiplication)
    """
    return A @ B  # NumPy matrix multiplication

def resolve_x(signal_handle):
    """
    Return the integer value of a signal, treating any 'x' or 'z' bits as 0.
    """
    try:
        return int(signal_handle.value)
    except ValueError:
        # Replace 'x' or 'z' bits with 0
        val_str = signal_handle.value.binstr.replace('x','0').replace('z','0')
        return int(val_str, 2)

def dump_memory(dut, start_addr=0, end_addr=0x3F, line_width=16):
    
    cocotb.log.info(f"=== Memory Dump [0x{start_addr:04X} .. 0x{end_addr:04X}] ===")
    addr = start_addr
    while addr <= end_addr:
        line_str = f"0x{addr:04X}: "
        for offset in range(line_width):
            if addr + offset <= end_addr:
                # dut.mem[addr + offset] は Verilog上で reg [7:0] mem[...] の単要素 (8bit)
                val = dut.uRV32IM.mem[addr + offset].value.integer  # 0~255
                line_str += f"{val:02X} "
            else:
                line_str += "   "
        cocotb.log.info(line_str)
        addr += line_width
    cocotb.log.info("============================================")

def data_trace_screen(dut):
    """
    Display the a_reg and b_reg values for all PEs as separate matrices.
    Assumes a hierarchical structure like ROW_BLOCK[r].COL_BLOCK[c].u_pe.
    """
    NUM_ROWS = 4
    NUM_COLS = 4

    # Create 4x4 arrays for a_reg and b_reg
    a_matrix = []
    b_matrix = []

    for r in range(NUM_ROWS):
        a_row = []
        b_row = []
        for c in range(NUM_COLS):
            pe = getattr(getattr(dut.u_systolic.ROW_BLOCK[r], f"COL_BLOCK[{c}]"), "u_pe")

            a_val = resolve_x(pe.a_reg)
            b_val = resolve_x(pe.b_reg)
            a_row.append(a_val)
            b_row.append(b_val)

        a_matrix.append(a_row)
        b_matrix.append(b_row)

    print("\n=== Current PE State (Matrix Format) ===")

    # Display a_reg matrix
    print(">>> a_reg:")
    print("[")
    for r in range(NUM_ROWS):
        # Display elements of row r separated by spaces
        row_str = " ".join(str(val) for val in a_matrix[r])
        print(f" [{row_str}]")
    print("]")

    print("")

    # Display b_reg matrix
    print(">>> b_reg:")
    print("[")
    for r in range(NUM_ROWS):
        row_str = " ".join(str(val) for val in b_matrix[r])
        print(f" [{row_str}]")
    print("]")
    print("")

@cocotb.test()
async def test_systolic_array(dut):
    """
    Simulation test using cocotb.
    Compares the Python model's output with the Verilog (hardware) output.
    """

    # 1. Clock generation
    clock = Clock(dut.Clock, 10, units="ns")  # 10ns period = 100MHz
    cocotb.start_soon(clock.start())
    data_trace_screen(dut)

    # 2. Reset sequence
    dut.rst_n.value = 0
    dut.data_clear.value = 1
    dut.en_b_shift_bottom.value = 0
    dut.en_shift_right.value = 0
    dut.en_shift_bottom.value = 0

    # Wait for a few cycles
    for _ in range(5):
        await RisingEdge(dut.Clock)

    dut.rst_n.value = 1
    dut.data_clear.value = 0

    for _ in range(5):
        await RisingEdge(dut.Clock)

    # Wait for stabilization
    for _ in range(5000):
        await RisingEdge(dut.Clock)
    data_trace_screen(dut)

    print("=============== Output data =======================")
    # --- メモリダンプを呼び出す ---
    # たとえば、先頭64バイトだけダンプする場合:
    dump_memory(dut, start_addr=0x0000, end_addr=0x0320, line_width=16)

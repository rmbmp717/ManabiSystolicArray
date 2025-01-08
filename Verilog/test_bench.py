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

    # 2. Reset sequence
    dut.rst_n.value = 0
    dut.data_clear.value = 1
    dut.en_shift_right.value = 0
    dut.en_shift_bottom.value = 0

    # Initialize B values
    for r in range(4):
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 0
            getattr(dut, f"b_reg_array_flat[{flat_index}]").value = int(0)

    # Initialize A values
    for r in range(4):
        getattr(dut, f"a_left_in_flat[{r}]").value = int(0)

    # Initialize ps_top_in_flat
    for c in range(4):
        getattr(dut, f"ps_top_in_flat[{c}]").value = int(0)

    # Wait for a few cycles
    for _ in range(25):
        await RisingEdge(dut.Clock)

    dut.rst_n.value = 1
    dut.data_clear.value = 0

    for _ in range(5):
        await RisingEdge(dut.Clock)

    # 3. Generate test data for A and B (4x4 matrices)
    A_np = np.random.randint(0, 10, (4, 4))  # Small values for clarity
    B_np = np.random.randint(0, 10, (4, 4))
    C_expected = python_systolic_model(A_np, B_np)

    # Initialize a 4x4 zero matrix
    C_dut = np.zeros((4, 4), dtype=int)

    cocotb.log.info(f"A=\n{A_np}\nB=\n{B_np}\nExpected=\n{C_expected}")

    # 4. Write B values into each PE
    # Cast NumPy type to standard Python int
    for r in range(4):
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 1
            getattr(dut, f"b_reg_array_flat[{flat_index}]").value = int(B_np[r][c])
        await RisingEdge(dut.Clock)
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 0

    # Debug
    print("==============INPUT B=====================")
    data_trace_screen(dut)

    # 5. Shift A values into the leftmost PEs and perform partial_sum shifts
    for row_i in range(4 + (4 - 1)):
        for r in range(4):
            if row_i < 4:
                getattr(dut, f"a_left_in_flat[{r}]").value = int(A_np[row_i][r])
            else:
                getattr(dut, f"a_left_in_flat[{r}]").value = int(0)

        print("row_i=", row_i)
        await RisingEdge(dut.Clock)

        # Debug
        print("==============Before SHIFT=====================")
        data_trace_screen(dut)

        # Perform right shift
        dut.en_shift_right.value = 1
        await RisingEdge(dut.Clock)
        dut.en_shift_right.value = 0

        # Wait
        for _ in range(3):
            await RisingEdge(dut.Clock)

        # Debug
        print("==============After SHIFT=====================")
        data_trace_screen(dut)

        # Wait
        for _ in range(5):
            await RisingEdge(dut.Clock)

        # Shift partial_sum downward
        for _ in range(4):
            dut.en_shift_bottom.value = 1
            await RisingEdge(dut.Clock)
            dut.en_shift_bottom.value = 0

        # Wait
        for _ in range(2):
            await RisingEdge(dut.Clock)

        C_tmp = np.zeros(4, dtype=int)
        for col in range(4):
            C_tmp[col] = resolve_x(getattr(dut, f"ps_bottom_out_flat[{col}]"))

        cocotb.log.info(f"C_tmp = \n{C_tmp}")

        # Map C_tmp into C_dut from top left to bottom right
        for col in range(len(C_tmp)):
            row = row_i - col
            if 0 <= row < C_dut.shape[0]:
                C_dut[row, col] = C_tmp[col]

        cocotb.log.info(f"Updated HW result during step row_i={row_i} = \n{C_dut}")

        print("===============calc loop end =======================")

    # Wait for stabilization
    for _ in range(20):
        await RisingEdge(dut.Clock)

    print("=============== Output data =======================")
    cocotb.log.info(f"Updated HW result during step row_i={row_i} = \n{C_dut}")

    # 7. Compare Python model output with hardware output
    if not np.array_equal(C_dut, C_expected):
        raise cocotb.result.TestFailure(
            f"Mismatch:\nHW=\n{C_dut}\nExpected=\n{C_expected}"
        )
    else:
        cocotb.log.info("Test Passed! HW result matches Python model.")

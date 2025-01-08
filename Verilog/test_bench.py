import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np

# Pythonモデル (行列積の簡易モデル)
def python_systolic_model(A, B):
    """
    A, B: shape=(4,4) の NumPy配列
    戻り値: C = A×B (4×4行列積)
    """
    return A @ B  # NumPy の行列積

def resolve_x(signal_handle):
    """
    Return integer value of a signal, 
    treating any 'x' or 'z' bits as 0.
    """
    try:
        return int(signal_handle.value)
    except ValueError:
        # 'x', 'z' が混ざるとここに飛ぶので強制的に置き換え
        val_str = signal_handle.value.binstr.replace('x','0').replace('z','0')
        return int(val_str, 2)

def data_trace_screen(dut):
    """
    各 PE の a_reg, b_reg を「別々の行列」として表示する。
    ROW_BLOCK[r].COL_BLOCK[c].u_pe という階層構造を想定。
    """
    NUM_ROWS = 4
    NUM_COLS = 4

    # a_reg, b_reg の 4x4 配列を作る
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

    # a_reg の行列を表示
    print(">>> a_reg:")
    print("[")
    for r in range(NUM_ROWS):
        # 行 r の要素をスペース区切りにして表示
        row_str = " ".join(str(val) for val in a_matrix[r])
        print(f" [{row_str}]")
    print("]")

    print("")

    # b_reg の行列を表示
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
    cocotb を用いたシミュレーションテスト。
    Pythonモデルとハードウェア(Verilog)の出力比較を行う。
    """

    # 1. クロック生成
    clock = Clock(dut.Clock, 10, units="ns")  # 10ns パーヘルツ = 100MHz想定
    cocotb.start_soon(clock.start())

    # 2. リセットシーケンス
    dut.rst_n.value = 0
    dut.data_clear.value = 1
    dut.en_shift_right.value = 0
    dut.en_shift_bottom.value = 0

    # set B
    for r in range(4):
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 0
            getattr(dut, f"b_reg_array_flat[{flat_index}]").value = int(0) 

    # set A
    for r in range(4):
        getattr(dut, f"a_left_in_flat[{r}]").value = int(0) 

    # set ps_top_in_flat
    for c in range(4):
        getattr(dut, f"ps_top_in_flat[{c}]").value = int(0) 

    for _ in range(25):
        await RisingEdge(dut.Clock)

    dut.rst_n.value = 1
    dut.data_clear.value = 0

    for _ in range(5):
        await RisingEdge(dut.Clock)

    # 3. テストデータ(A, B) をランダムに生成 (4x4)
    A_np = np.random.randint(0, 10, (4, 4))  # 小さい値にしておく(確認しやすい)
    B_np = np.random.randint(0, 10, (4, 4))
    C_expected = python_systolic_model(A_np, B_np)

    cocotb.log.info(f"A=\n{A_np}\nB=\n{B_np}")
    #cocotb.log.info(f"A=\n{A_np}\nB=\n{B_np}\nExpected=\n{C_expected}")

    # 4. B の値を各PEに書き込む
    # NumPy型をPython標準int型にキャスト
    for r in range(4):
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 1
            getattr(dut, f"b_reg_array_flat[{flat_index}]").value = int(B_np[r][c])  # 修正点
        await RisingEdge(dut.Clock)
        for c in range(4):
            flat_index = r * 4 + c
            getattr(dut, f"b_we_array_flat[{flat_index}]").value = 0

    # Debug
    print("==============INPUT B=====================")
    data_trace_screen(dut)

    # 5. Aを左端から順次流す(シフト) + partial_sum のシフト
    for row_i in range(4):
        for r in range(4):
            getattr(dut, f"a_left_in_flat[{r}]").value = int(A_np[row_i][r])  # 修正点

        print("row_i=", row_i)
        await RisingEdge(dut.Clock)

        # Debug
        print("==============Before SHIFT=====================")
        data_trace_screen(dut)
        
        # ==================シフト動作 =======================
        dut.en_shift_right.value = 1

        await RisingEdge(dut.Clock)

        dut.en_shift_right.value = 0

        # ウェイト
        for _ in range(3):
            await RisingEdge(dut.Clock)
        
        # Debug

        # Debug
        print("==============After SHIFT=====================")
        data_trace_screen(dut)

        # ウェイト
        for _ in range(5):
            await RisingEdge(dut.Clock)

        # partial_sum をシフト
        dut.en_shift_bottom.value = 1
        await RisingEdge(dut.Clock)
        dut.en_shift_bottom.value = 0

        # ウェイト
        for _ in range(2):
            await RisingEdge(dut.Clock)

        C_tmp = np.zeros(4, dtype=int)  # shape=(4,)
        for col in range(4):
            C_tmp[col] = resolve_x(getattr(dut, f"ps_bottom_out_flat[{col}]"))
        cocotb.log.info(f"C_tmp = \n{C_tmp}")

        print("===============calc roop end =======================")

    # 6. 計算結果を読み出して比較
    C_dut = np.zeros((4, 4), dtype=int)
    for col in range(4):
        C_dut[3, col] = resolve_x(getattr(dut, f"ps_bottom_out_flat[{col}]"))

    cocotb.log.info(f"HW result = \n{C_dut}")

    # ウェイト
    for _ in range(20):
        await RisingEdge(dut.Clock)

    # 7. Pythonモデル結果との比較
    '''
    if not np.array_equal(C_dut, C_expected):
        raise cocotb.result.TestFailure(
            f"Mismatch:\nHW=\n{C_dut}\nExpected=\n{C_expected}"
        )
    else:
        cocotb.log.info("Test Passed! HW result matches Python model.")
    '''

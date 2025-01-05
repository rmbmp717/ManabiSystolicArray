import numpy as np

class PE:
    def __init__(self, row, col, b_val=0):
        self.row = row
        self.col = col
        self.b_val = b_val
        self.a_reg = 0
        self.partial_sum = 0

        # 上下左右のセル参照 (初期は None)
        self.top = 0
    def calc_step(self):
        self.partial_sum = self.a_reg * self.b_val

    def shift_step(self):
        if self.top:  # 上のセルが存在する場合
            self.partial_sum += self.top.partial_sum  # 上セルの partial_sum を加算

    def flush(self):
        return self.partial_sum

class SystolicArray:

    def __init__(self, B):
        self.rows = 3
        self.cols = 1

        # PE配列を初期化
        self.pes = []
        for r in range(self.rows):
            row_pes = []
            for c in range(self.cols):
                pe = PE(r, c, b_val=B[r][c])
                row_pes.append(pe)
            self.pes.append(row_pes)

        # 上下左右リンク
        self._link_pes()

    def _link_pes(self):
        for r in range(self.rows):
            if r > 0:
                self.pes[r][0].top = self.pes[r-1][0]  # 隣接する PE オブジェクトを参照


    def _trace(self, step, A, B):
        print(f"\nStep={step})")

        # A_regを収集（Aは1行3列）
        A_reg_mat = []
        for r in range(len(A)):
            a_row = [A[r][c] for c in range(len(A[0]))]
            A_reg_mat.append(a_row)

        # B_valを3行1列で表示
        B_val_mat = np.array(B)  # Bは3行1列のまま表示

        # partial_sumを3行1列で収集
        PS_mat = [[self.pes[r][0].partial_sum] for r in range(self.rows)]  # 各PEのpartial_sumを収集

        # 表示
        print(" A_reg =\n", np.array(A_reg_mat))  # 1行3列
        print(" b_val =\n", B_val_mat)  # 3行1列
        print(" partial_sum =\n", np.array(PS_mat))  # 3行1列

    def multiply(self, A, B):
        A = np.array(A)   # shape=(1,3)

        out = np.zeros((3,1), dtype=int)

        # Aの代入
        self.pes[0][0].a_reg = A[0][0]
        self.pes[1][0].a_reg = A[0][1]
        self.pes[2][0].a_reg = A[0][2]
        self._trace(1, A, B)

        print("=======================================")
        print("Calc")

        # 3セル計算
        for rr in range(self.rows):
            self.pes[rr][0].calc_step()
            self._trace(2, A, B)

        print("=======================================")
        print("SHIFT")

        # 3回SHIFT
        for rr in range(self.rows):
            self._link_pes()
            self.pes[rr][0].shift_step()
            self._trace(3, A, B)

        print("=======================================")

        # flush => (3×2)
        out = self.pes[2][0].flush()

        return out


def main():
    # A
    A = [
        [1,2,3]
    ]
    # B
    B = [
        [11],
        [13],
        [15]
    ]

    # Aの行数と列数を取得
    rows = len(A)  # 行数
    cols = len(A[0]) if rows > 0 else 0  # 列数（最初の行の要素数）

    print(f"A の形状: {rows} 行 x {cols} 列")
    print(f"A の内容: {A}")

    # Bの行数と列数を取得
    rows = len(B)  # 行数
    cols = len(B[0]) if rows > 0 else 0  # 列数（最初の行の要素数）

    print(f"B の形状: {rows} 行 x {cols} 列")
    print(f"B の内容: {B}")

    # 行列積の計算
    A_np = np.array(A)
    B_np = np.array(B)
    expected_out = np.dot(A_np, B_np)  # NumPyでの行列積
    print(f"NumPy での行列積の結果: {expected_out.flatten()[0]}")

    # Systolic Arrayの計算
    sa = SystolicArray(B)
    out = sa.multiply(A, B)
    print("Systolic Array の結果:", out)

    # アサート
    assert out == expected_out.flatten()[0], f"期待値 {expected_out.flatten()[0]} と結果 {out} が一致しません"
    print("結果は正しいです！")

    print("out=", out)

if __name__=="__main__":
    main()

import numpy as np

class SystolicCell:
    """
    シストリックアレイの1セル（Processing Element, PE）をシミュレートするクラス。
    入力 A, B を受け取り、内部で A * B を累積して保持し、次のセルに A, B を渡す。
    """
    def __init__(self, row, col):
        self.row = row
        self.col = col
        self.partial_sum = 0  # 出力結果を蓄積するレジスタ
        self.a_reg = 0        # データ A を一時保持するレジスタ
        self.b_reg = 0        # データ B を一時保持するレジスタ

    def step(self, a_in, b_in):
        """
        1ステップごとに A, B を受け取り、演算を行い、次のセルに伝搬する。
        """
        # 前ステップで保持していたレジスタの値を使って加算
        self.partial_sum += self.a_reg * self.b_reg

        # レジスタの更新 (新しい入力をレジスタに登録)
        self.a_reg = a_in
        self.b_reg = b_in

        # 出力としては次のセルへ A, B をそのまま伝搬する
        return self.a_reg, self.b_reg

    def flush(self):
        """
        最後にレジスタ内にあるデータを使って積算結果を反映し、partial_sum を返す。
        実際のハードウェアの場合はパイプラインのフラッシュなどに相当する処理。
        """
        self.partial_sum += self.a_reg * self.b_reg
        return self.partial_sum

class SystolicArray:
    def __init__(self, size):
        self.size = size
        self.cells = [[SystolicCell(r, c) for c in range(size)] for r in range(size)]

    def multiply(self, A, B):
        A = np.array(A)
        B = np.array(B)

        C = np.zeros((self.size, self.size), dtype=np.float64)
        total_steps = 2 * self.size

        for t in range(total_steps):
            print("=" * 30)
            print(f"step = {t}")
            print("A =")
            print(A)
            print("B =")
            print(B)

            for r in range(self.size):
                for c in range(self.size):
                    # A を右に、B を下にシフト
                    if 0 <= t - r < self.size:
                        a_in = A[r, t - r]  # A は同じ行で列をシフト
                    else:
                        a_in = 0

                    if 0 <= t - c < self.size:
                        b_in = B[t - c, c]  # B は同じ列で行をシフト
                    else:
                        b_in = 0

                    print(f"r={r}, c={c}, a_in={a_in}, b_in={b_in}")
                    self.cells[r][c].step(a_in, b_in)

        # フラッシュ処理
        for r in range(self.size):
            for c in range(self.size):
                C[r, c] = self.cells[r][c].flush()

        return C



def main():
    A = [[1, 2],
         [3, 4]]
    B = [[5, 6],
         [7, 8]]

    size = 2
    systolic_array = SystolicArray(size)
    result = systolic_array.multiply(A, B)

    print("A =")
    print(np.array(A))
    print("B =")
    print(np.array(B))
    print("C = A x B (シストリックアレイによるシミュレーション結果)")
    print(result)

    check = np.dot(A, B)
    print("NumPy による行列積:")
    print(check)


if __name__ == "__main__":
    main()

import numpy as np

class SystolicCell:
    """
    2x2 シストリックセル。
    上下左右のセルへの参照を持ちつつ、内部で a_reg, b_reg, partial_sum を保持。
    """
    def __init__(self, row, col):
        self.row = row
        self.col = col

        # 上下左右のセル参照 (初期は None)
        self.top = None
        self.bottom = None
        self.left = None
        self.right = None

        # レジスタや内部状態
        self.a_reg = 0.0
        self.b_reg = 0.0
        self.partial_sum = 0.0

    def step(self, a_in, b_in):
        """
        1ステップごとに:
          1) 前ステップで保持していた (a_reg, b_reg) の積を partial_sum に加算
          2) 新たに受け取った a_in, b_in をレジスタに保存
        """
        self.partial_sum += self.a_reg * self.b_reg
        self.a_reg = a_in
        self.b_reg = b_in

    def flush(self):
        """
        最後にレジスタ内に残っている (a_reg * b_reg) を partial_sum に加算して返す
        """
        self.partial_sum += self.a_reg * self.b_reg
        return self.partial_sum


class SystolicArray2x2:
    """
    2x2 のシストリックアレイ。
      - cells[r][c] (r,c in {0,1}) の4セル
      - セル同士を上下左右で接続
      - multiply(A, B) で行列 A(2x2) × B(2x2) を計算
    """
    def __init__(self):
        # 2×2 のセルを生成
        self.cells = []
        for r in range(2):
            row_cells = []
            for c in range(2):
                row_cells.append(SystolicCell(r, c))
            self.cells.append(row_cells)

        # 上下左右をリンク
        for r in range(2):
            for c in range(2):
                cell = self.cells[r][c]
                if r > 0:
                    cell.top = self.cells[r-1][c]
                if r < 1:
                    cell.bottom = self.cells[r+1][c]
                if c > 0:
                    cell.left = self.cells[r][c-1]
                if c < 1:
                    cell.right = self.cells[r][c+1]

    def multiply(self, A, B):
        """
        A, B: いずれも 2x2 の行列
        シンプルに「k = t - (r + c)」方式で 4ステップ回して行列積を計算
        """
        A = np.array(A)
        B = np.array(B)

        # 2×2 の場合、ステップは 2*2 = 4
        total_steps = 2 * 2

        for t in range(total_steps):
            for r in range(2):
                for c in range(2):
                    # 対角方向のシフトを表す式 k = t - (r + c)
                    k = t - (r + c)
                    if 0 <= k < 2:
                        a_in = A[r, k]
                        b_in = B[k, c]
                    else:
                        a_in = 0
                        b_in = 0

                    self.cells[r][c].step(a_in, b_in)

        # 計算終了後、flush() で各セルの partial_sum を集める
        C = np.zeros((2,2), dtype=np.float64)
        for r in range(2):
            for c in range(2):
                C[r, c] = self.cells[r][c].flush()

        return C


def main():
    A = [[1, 2],
         [3, 4]]
    B = [[5, 6],
         [7, 8]]

    sa = SystolicArray2x2()
    C = sa.multiply(A, B)

    print("A =\n", np.array(A))
    print("B =\n", np.array(B))
    print("C (Systolic) =\n", C)
    print("C (NumPy)    =\n", np.dot(A, B))

    assert np.allclose(C, np.dot(A, B)), "Systolic array result doesn't match NumPy result!"
    print("\033[94m結果が一致しました。\033[0m")

if __name__ == "__main__":
    main()

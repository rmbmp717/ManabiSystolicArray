import numpy as np

class SystolicCell:
    def __init__(self):
        self.partial_sum = 0
        self.a_reg = 0
        self.b_reg = 0

    def step(self, a_in, b_in):
        """
        1ステップ分の演算 (パイプライン1段遅れ):
          - 前のステップで保持していた a_reg, b_reg の積を partial_sum に加算
          - 今ステップの入力 (a_in, b_in) をレジスタに保存
        """
        # 1. 前ステップ分を加算
        self.partial_sum += self.a_reg * self.b_reg

        # 2. 今ステップ分をレジスタに保存
        self.a_reg = a_in
        self.b_reg = b_in

    def flush(self):
        """
        最終フラッシュ: レジスタにまだ残っている (a_reg, b_reg) の積を加算し、partial_sum を返す
        """
        self.partial_sum += self.a_reg * self.b_reg
        return self.partial_sum


class SystolicArray:
    def __init__(self, size):
        self.size = size
        # size×size のセル配列 (2×2)
        self.SA_cells = [[SystolicCell() for _ in range(size)] for _ in range(size)]

    def multiply(self, A, B):
        A = np.array(A)
        B = np.array(B)
        C = np.zeros((self.size, self.size), dtype=np.float64)

        # ステップ数は 2*size (2×2なら 4ステップ)
        # パイプライン1段遅れ + 入力が全セルに行き渡るまで
        total_steps = 2 * self.size

        # 各ステップでセル (r,c) に A, B の該当要素を入力
        for t in range(total_steps):
            print("===================================")
            print("t=", t)
            for r in range(self.size):
                for c in range(self.size):
                    # 波がセル (r,c) に届くかどうか判定
                    # t - (r + c) が 0 <= < size のときだけ実データを入力
                    k = t - (r + c)
                    print("===================")
                    print("r=",r, ", c=", c)
                    print("k=",k)
                    if 0 <= k < self.size:
                        a_in = A[r, k]
                        b_in = B[k, c]
                    else:
                        a_in = 0
                        b_in = 0

                    self.SA_cells[r][c].step(a_in, b_in)

        # 全セルを flush して、最終結果を C に書き込む
        print("================END==================")
        for r in range(self.size):
            for c in range(self.size):
                C[r, c] = self.SA_cells[r][c].flush()

        return C


def main():
    # 2×2 の行列
    A = [[6, 2],
         [12, 4]]
    B = [[5, 6],
         [8, 8]]

    systolic_array = SystolicArray(size=2)
    C = systolic_array.multiply(A, B)

    print("A =")
    print(np.array(A))
    print("B =")
    print(np.array(B))

    print("C = A x B (シストリックアレイで計算)")
    print(C)

    np_result = np.dot(A, B)
    print("NumPy =")
    print(np_result)
    
    # NumPy の結果とシストリックアレイの結果が近いかどうかアサートで確認
    assert np.allclose(C, np_result), "Systolic array result doesn't match NumPy result!"
    print("結果が一致しました。")


if __name__ == "__main__":
    main()

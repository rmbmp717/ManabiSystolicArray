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
    """
    行列同士の乗算を行うためのシストリックアレイをシミュレートするクラス。
    """
    def __init__(self, size):
        self.size = size
        # size x size のセルを作成
        self.cells = [[SystolicCell(r, c) for c in range(size)] for r in range(size)]

    def multiply(self, A, B):
        """
        行列 A, B (いずれも size x size) の積 C = A x B をシミュレートする。
        """
        # A, B を numpy array に変換
        A = np.array(A)
        B = np.array(B)

        # 乗算結果 C を 0 初期化
        C = np.zeros((self.size, self.size), dtype=np.float64)

        # ステップ数は (2 * size - 1) 回分考える
        # シフトして入力が全セルに行き渡るまで + フラッシュ時間 というイメージ
        total_steps = 2 * self.size 

        for t in range(total_steps):
            # 各行・列のセルに入力を与える
            for r in range(self.size):
                for c in range(self.size):
                    # このセルに入る A, B を計算する
                    # A は上に移動する、B は左に移動するようなイメージ
                    # t - r - c が 0 以上の場合に、実際にその要素が届いているとみなす
                    # (右下方向に演算結果が流れるイメージ)
                    if 0 <= t - r - c < self.size:
                        a_in = A[r, t - r - c]
                        b_in = B[t - r - c, c]
                    else:
                        a_in = 0
                        b_in = 0

                    # 1ステップ分演算
                    self.cells[r][c].step(a_in, b_in)

        # 全セルのフラッシュを行い、最終結果を C に書き込む
        for r in range(self.size):
            for c in range(self.size):
                C[r, c] = self.cells[r][c].flush()

        return C


def main():
    # サンプル行列（2x2）
    A = [[1, 2],
         [3, 4]]
    B = [[5, 6],
         [7, 8]]

    # シストリックアレイのインスタンスを作る
    size = 2
    systolic_array = SystolicArray(size)

    # 演算
    result = systolic_array.multiply(A, B)

    print("A =")
    print(np.array(A))
    print("B =")
    print(np.array(B))
    print("C = A x B (シストリックアレイによるシミュレーション結果)")
    print(result)

    # NumPy の行列積による確認
    check = np.dot(A, B)
    print("NumPy による行列積:")
    print(check)


if __name__ == "__main__":
    main()

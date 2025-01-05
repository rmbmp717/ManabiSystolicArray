import numpy as np

class PE:
    """
    Processing Element (PE) クラス。
    B の要素 b_val を保持し、A の要素を受け取って計算を実行。
    """
    def __init__(self, row, col, b_val=0):
        self.row = row  # PE の行インデックス
        self.col = col  # PE の列インデックス
        self.b_val = b_val  # B の値を保持
        self.a_reg = 0  # A の値を保持
        self.partial_sum = 0  # 部分和

        # 上のセル参照（隣接する PE をリンク）
        self.top = None

    def calc_step(self):
        """
        計算ステップ：
        A_reg × b_val の積を partial_sum に加算（累積）。
        """
        self.partial_sum += self.a_reg * self.b_val

    def shift_step(self):
        """
        シフトステップ：
        上のセルから partial_sum を受け取り、自分の partial_sum に加算。
        """
        if self.top:
            self.partial_sum += self.top.partial_sum

    def reset(self):
        """
        partial_sum と a_reg をリセット。
        """
        self.partial_sum = 0

    def flush(self):
        """
        現在の部分和 (partial_sum) を返す。
        """
        return self.partial_sum


class SystolicArray3x2:
    """
    3×2 の Systolic Array を構築し、
    A(2×3) × B(3×2) の行列積を計算する簡易版。
    """
    def __init__(self, B):
        """
        B を受け取り、PE 配列を初期化。
        """
        B = np.array(B)  # B を NumPy 配列に変換

        # 配列のサイズを取得
        self.rows = B.shape[0]  # 行数
        self.cols = B.shape[1]  # 列数

        # PE 配列を構築
        self.pes = []
        for r in range(self.rows):
            row_pes = []
            for c in range(self.cols):
                pe = PE(r, c, b_val=B[r, c])
                row_pes.append(pe)
            self.pes.append(row_pes)

        # 上方向のリンクを設定
        self._link_pes()

    def _link_pes(self):
        """
        PE 配列内の上下リンクを設定。
        """
        for r in range(self.rows):
            for c in range(self.cols):
                if r > 0:
                    self.pes[r][c].top = self.pes[r - 1][c]

    def reset(self):
        """
        配列内のすべての PE をリセット。
        """
        for r in range(self.rows):
            for c in range(self.cols):
                self.pes[r][c].reset()

    def right_shift(self):
        """
        a_reg を右方向にシフト。
        左端 (col=0) の値はクリアする。
        """
        for r in range(self.rows):
            for c in range(self.cols - 1, 0, -1):
                self.pes[r][c].a_reg = self.pes[r][c - 1].a_reg
            self.pes[r][0].a_reg = 0

    def _trace(self, step, A, B):
        """
        各ステップでの PE 配列の状態をデバッグ表示。
        """
        print(f"\nStep={step}")
        print("A の内容:")
        print(np.array(A))
        print("\nB の内容:")
        print(np.array(B))

        # b_val の状態を表示
        B_val_mat = [[self.pes[r][c].b_val for c in range(self.cols)] for r in range(self.rows)]
        print("\nB_val (PE に格納された B の値):")
        print(np.array(B_val_mat))

        # partial_sum の状態を表示
        PS_mat = [[self.pes[r][c].partial_sum for c in range(self.cols)] for r in range(self.rows)]
        print("\npartial_sum (計算途中の部分和):")
        print(np.array(PS_mat))

        # a_reg の状態を表示
        A_reg_mat = [[self.pes[r][c].a_reg for c in range(self.cols)] for r in range(self.rows)]
        print("\na_reg (PE に格納された A の値):")
        print(np.array(A_reg_mat))

    def multiply(self, A, B):
        """
        A: shape = (2,3)
        B: shape = (3,2)
        出力: shape = (2,2)
        """
        A = np.array(A)  # A を NumPy 配列に変換
        B = np.array(B)  # B を NumPy 配列に変換

        # 結果を格納する行列を初期化
        out = np.zeros((A.shape[0], B.shape[1]), dtype=int)

        print("\n=== 初期状態 ===")
        self._trace(0, A, B)

        # A の各行について計算
        for a_row_i in range(A.shape[0] + 1):
            print(f"\n=== A の行 {a_row_i} の計算開始 ===")

            # 全 PE をリセット
            self.reset()

            # **右方向シフト**
            self.right_shift()

            # A の次の行を左端に代入
            if a_row_i < A.shape[0]:
                a_row = A[a_row_i]
            for r in range(self.rows):
                if a_row_i < A.shape[0]:
                    self.pes[r][0].a_reg = a_row[r]

            # トレース：代入後の状態を確認
            self._trace(f"{a_row_i}-1-代入とシフト", A, B)

            # 各 PE で calc_step を実行
            for r in range(self.rows):
                for c in range(self.cols):
                    self.pes[r][c].calc_step()

            # トレース：calc_step 実行結果を確認
            self._trace(f"{a_row_i}-2-計算", A, B)

            # 各 PE で shift_step を実行
            for r in range(self.rows):
                for c in range(self.cols):
                    self.pes[r][c].shift_step()

            # トレース：shift_step 実行結果を確認
            self._trace(f"{a_row_i}-3-シフト", A, B)

            # **結果収集**
            for c in range(self.cols):
                if c == 0:  # 1列目はそのまま代入
                    if a_row_i < A.shape[0]:
                        out[a_row_i, c] = self.pes[self.rows - 1][c].flush()
                        print(f"a_rou={a_row_i}, c={c}, flush={out[a_row_i, c]}")
                elif c == 1 and a_row_i > 0:  # 2列目は前の行に代入
                    out[a_row_i - 1, c] = self.pes[self.rows - 1][c].flush()
                    print(f"a_rou={a_row_i - 1}, c={c}, flush={out[a_row_i - 1, c]}")

            print(f"\n=== A の行 {a_row_i} の計算終了 ===")

        return out


def main():
    # 入力行列 A (2×3) と B (3×2)
    A = [
        [1, 2, 3],
        [4, 5, 6],
    ]
    B = [
        [10, 11],
        [12, 13],
        [14, 15],
    ]

    # 期待される結果 (NumPy で計算)
    A_np = np.array(A)
    B_np = np.array(B)
    expected = A_np.dot(B_np)

    # Systolic Array を作成して計算
    sa = SystolicArray3x2(B)
    result = sa.multiply(A, B)

    # 結果を表示
    print("A (2×3):")
    print(A_np)
    print("B (3×2):")
    print(B_np)

    print("\n=== NumPy の行列積 ===")
    print(expected)

    print("\n=== Systolic Array の計算結果 ===")
    print(result)

    # 結果の検証
    assert np.allclose(result, expected), f"NG: {result} != {expected}"
    print("\n=== 計算が正しいことを確認しました ===")


if __name__ == "__main__":
    main()

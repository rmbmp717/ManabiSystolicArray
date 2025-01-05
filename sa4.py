import numpy as np

class PE:
    """
    Bの要素 b_val を保持し、Aの要素を受け取って partial_sum に積算し、
    上からの加算(shift_step)を行う簡易PE。
    """
    def __init__(self, row, col, b_val=0):
        self.row = row
        self.col = col
        self.b_val = b_val
        self.a_reg = 0
        self.partial_sum = 0

        # 上のセル参照（None でない場合は PEオブジェクト）
        self.top = None

    def calc_step(self):
        """
        A_reg と b_val の積を partial_sum に加算（累積）。
        実際のsystolic arrayだと1クロックごとに a_reg が変わったりしますが、
        ここでは単純化して「受け取ったA_regを即時に積算」のみ。
        """
        self.partial_sum += self.a_reg * self.b_val

    def shift_step(self):
        """
        上からの partial_sum をさらに加算（累積）。
        (本来はPEの上下左右連携などあるが、ここでは上方向のみリンク)
        """
        if self.top:
            self.partial_sum += self.top.partial_sum

    def reset(self):
        """partial_sum と a_reg をリセット。"""
        self.partial_sum = 0

    def flush(self):
        """
        最終結果を取り出す。
        """
        return self.partial_sum


class SystolicArray3x2:
    """
    B と同じ形状 (3×2) のSystolic Arrayを構築し、
    A(2×3)との行列積 (2×2) を計算する簡易版サンプル。
    """

    def __init__(self, B):
        """
        B: shape = (3,2)
        self.rows = 3
        self.cols = 2
        """
        B = np.array(B)  # shape=(3,2)

        # B と同じ形状のSystolic Array
        self.rows = B.shape[0]  # 3
        self.cols = B.shape[1]  # 2

        # PE配列初期化
        self.pes = []
        for r in range(self.rows):
            row_pes = []
            for c in range(self.cols):
                pe = PE(r, c, b_val=B[r,c])
                row_pes.append(pe)
            self.pes.append(row_pes)

        # 上方向のリンクのみ設定
        self._link_pes()

    def _link_pes(self):
        for r in range(self.rows):
            for c in range(self.cols):
                if r > 0:
                    self.pes[r][c].top = self.pes[r-1][c]

    def reset(self):
        """
        全PEの状態をリセットするメソッド。
        """
        for r in range(self.rows):
            for c in range(self.cols):
                self.pes[r][c].reset()

    def right_shift(self):
        """
        Systolic Array 内のすべての PE の a_reg を右方向にシフトする。
        """
        for r in range(self.rows):  # 各行を処理
            for c in range(self.cols - 1, 0, -1):  # 右端から左端へシフト
                self.pes[r][c].a_reg = self.pes[r][c - 1].a_reg  # 右にシフト
            # 左端（col=0）はクリアする（前回のデータが残らないように）
            self.pes[r][0].a_reg = 0

    def _trace(self, step, A, B):
        """
        各計算ステップでのPEの内部状態を表示するデバッグ用メソッド。
        """
        print(f"\nStep={step}")

        # A の表示
        print("A の内容:")
        print(np.array(A))

        # B の表示
        print("\nB の内容:")
        print(np.array(B))

        # b_val（Bの各PEに割り当てられている値）の表示
        B_val_mat = [[self.pes[r][c].b_val for c in range(self.cols)] for r in range(self.rows)]
        print("\nB_val (PE に格納された B の値):")
        print(np.array(B_val_mat))

        # partial_sum の表示
        PS_mat = [[self.pes[r][c].partial_sum for c in range(self.cols)] for r in range(self.rows)]
        print("\npartial_sum (計算途中の部分和):")
        print(np.array(PS_mat))

        # a_reg の表示
        A_reg_mat = [[self.pes[r][c].a_reg for c in range(self.cols)] for r in range(self.rows)]
        print("\na_reg (PE に格納された A の値):")
        print(np.array(A_reg_mat))

    def _traceA(self, step, A):
        """
        各計算ステップでのPEの内部状態を表示するデバッグ用メソッド。
        """
        print(f"\nStep={step}")

        # a_reg の表示
        A_reg_mat = [[self.pes[r][c].a_reg for c in range(self.cols)] for r in range(self.rows)]
        print("\na_reg (PE に格納された A の値):")
        print(np.array(A_reg_mat))



    def multiply(self, A, B):
        """
        A: shape = (2,3)
        B: shape = (3,2)
        出力: shape = (2,2)
        """
        A = np.array(A)  # shape=(2,3)
        B = np.array(B)  # shape=(3,2)

        out = np.zeros((A.shape[0], B.shape[1]), dtype=int)  # 結果は (A行数 × B列数)

        print("\n=== 初期状態 ===")
        self._trace(0, A, B)

        # A の各行について計算
        for a_row_i in range(A.shape[0]):  # Aの行を順次処理
            print(f"\n=== A の行 {a_row_i} の計算開始 ===")

            # 全PEをリセット
            self.reset()

            # **右方向シフト**
            print("\n=== シフト前のトレース ===")
            self._traceA(99, A)
            self.right_shift()
            print("\n=== シフト後のトレース ===")
            self._traceA(100, A)

            # 次の A の行を左端に代入
            a_row = A[a_row_i]
            for r in range(self.rows):
                self.pes[r][0].a_reg = a_row[r]  # 左端に新しい値を設定

            # トレース：代入後の状態を確認
            self._trace(f"{a_row_i}-1-代入とシフト", A, B)

            # 各 PE で calc_step を実行（すべての列を処理）
            for r in range(self.rows):
                for c in range(self.cols):
                    self.pes[r][c].calc_step()

            # トレース：calc_step 実行結果を確認
            self._trace(f"{a_row_i}-2-計算", A, B)

            # 各 PE で shift_step を実行（すべての列を処理）
            for r in range(self.rows):
                for c in range(self.cols):
                    self.pes[r][c].shift_step()

            # トレース：shift_step 実行結果を確認
            self._trace(f"{a_row_i}-3-シフト", A, B)

            # **結果収集（行ごとに処理）**
            for c in range(self.cols):
                out[a_row_i, c] = self.pes[self.rows - 1][c].flush()
                print()

            print(f"\n=== A の行 {a_row_i} の計算終了 ===")
            self._trace(f"{a_row_i}-final", A, B)

        return out

def main():
    # A: 2×3
    A = [
        [1, 2, 3],
        [4, 5, 6],
    ]
    # B: 3×2
    B = [
        [10, 11],
        [12, 13],
        [14, 15],
    ]

    # 期待される結果 (NumPy計算)
    A_np = np.array(A)  # shape=(2,3)
    B_np = np.array(B)  # shape=(3,2)
    expected = A_np.dot(B_np)  # shape=(2,2)

    # Systolic Array (3×2)
    sa = SystolicArray3x2(B)
    result = sa.multiply(A,B)

    print("A (2×3):")
    print(np.array(A))
    print("B (3×2):")
    print(np.array(B))

    print("\n=== NumPy の行列積 ===")
    print(expected)

    print("\n=== Systolic Array の計算結果 (簡易) ===")
    print(result)

    # 検証
    assert np.allclose(result, expected), f"NG: {result} != {expected}"
    print("\n=== 計算が正しいことを確認しました ===")


if __name__ == "__main__":
    main()

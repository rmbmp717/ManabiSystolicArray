#include <stdint.h>  // for uintptr_t

// RAMとして使える領域を想定
#define TARGET_ADDR  0x140

int _start(void)
{
    // 書き込み元の2x2行列 (好きな値でOK)
    volatile uint32_t arrA[2][2] = {
        {0x11111111, 0x22222222},
        {0x33333333, 0x44444444}
    };

    volatile uint32_t arrB[2][2] = {
        {0x55555555, 0x66666666},
        {0x77777777, 0x88888888}
    };

    // 加算結果を格納する 2x2 のローカル変数
    volatile uint32_t sum[2][2];

    // 行列の要素を加算
    //   sum[i][j] = arrA[i][j] + arrB[i][j]
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            sum[i][j] = arrA[i][j] + arrB[i][j];
        }
    }

    // メモリ書き込み先アドレス (0x120~) を指すポインタを作成
    volatile uint32_t *p = (volatile uint32_t *)(uintptr_t)TARGET_ADDR;

    // sum[2][2] の内容を順に書き込む
    //   計4要素 (それぞれ4バイト) → 合計16バイト
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            *p++ = sum[i][j];
        }
    }

    // おまけで1ワード (0x11) を最後に書き込む
    *p++ = 0x11;

    // 無限ループに入り、実行終了させない
    while (1) {
        // 何もしない
    }

    // 実際には到達しない
    return 0;
}

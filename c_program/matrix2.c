#include <stdint.h>  // for uintptr_t

// RAMとして使える領域を想定
#define TARGET_ADDR  0x120

//int global_var = 0x12345678;  // ここに入る
//int global_array[10];  // 初期値なし -> BSS

int _start(void)
{
    // 書き込み元の2x2配列(好きな値を入れてOK)
    volatile uint32_t arr[2][2] = {
        {0x11111111, 0x22222222},
        {0x33333333, 0x44444444}
    };

    // メモリ書き込み先アドレスを指すポインタを作成 (0x120 以降へ書き込み)
    volatile uint32_t *p = (volatile uint32_t *)(uintptr_t)TARGET_ADDR;

    // 2x2 配列のコピー
    // arr[i][j] を順番に TARGET_ADDR に書き込む (合計4要素)
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            *p++ = arr[i][j];
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

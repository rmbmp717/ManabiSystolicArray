#include <stdint.h>  // for uintptr_t

// RAMとして使える領域を想定
#define TARGET_ADDR  0x140
#define TARGET_ADDR2  0x260

int _start(void)
{
    // 書き込み元の4x4行列
    volatile uint32_t arrA[4][4] = {
        {0x11111111, 0x22222222, 0x33333333, 0x44444444},
        {0x55555555, 0x66666666, 0x77777777, 0x88888888},
        {0x99999999, 0xAAAAAAAA, 0xBBBBBBBB, 0xCCCCCCCC},
        {0xDDDDDDDD, 0xEEEEEEEE, 0xFFFFFFFF, 0x00000000}
    };

    volatile uint32_t arrB[4][4] = {
        {0x12345678, 0x23456789, 0x3456789A, 0x456789AB},
        {0x56789ABC, 0x6789ABCD, 0x789ABCDE, 0x89ABCDEF},
        {0x9ABCDEF0, 0xABCDEFFF, 0xBCDEFFFF, 0xCDEFFFFF},
        {0xDEFFFFFF, 0xEFFFFFFF, 0xFFFFFFFF, 0x11111111}
    };

    // 加算結果と乗算結果を格納する 4x4 のローカル変数
    volatile uint32_t sum[4][4];
    volatile uint32_t product[4][4];

    // 行列の要素を加算と乗算
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            sum[i][j] = arrA[i][j] + arrB[i][j];
            product[i][j] = arrA[i][j] * arrB[i][j];
        }
    }

    // メモリ書き込み先アドレス (0x140~) を指すポインタを作成
    volatile uint32_t *p = (volatile uint32_t *)(uintptr_t)TARGET_ADDR;
    volatile uint32_t *p2 = (volatile uint32_t *)(uintptr_t)TARGET_ADDR2;

    // sum[4][4] の内容を順に書き込む
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            *p++ = sum[i][j];
            //*p++ = arrA[i][j];
        }
    }
    
    *p++ = 0xDEADBEEF;

    // product[4][4] の内容を順に書き込む
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            //*p++ = product[i][j];
            *p++ = arrB[i][j];
        }
    }

    // 終了マークをメモリに書き込む
    //*p++ = 0xDEADBEEF;
    *p2 = 0x11334411;

    // 無限ループに入り、実行終了させない
    while (1) {
        // 何もしない
    }

    // 実際には到達しない
    return 0;
}

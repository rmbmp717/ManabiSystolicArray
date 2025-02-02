#include <stdint.h>  // uint32_t 型を使うために必要

#define TARGET_ADDR  0x280

// 固定アドレスでメモリを確保する方法
volatile uint32_t mul[4][4];

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

    // sumの内容を初期化または計算
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            //sum[i][j] = i * 4 + j; // デモ用の値
            mul[i][j] = arrA[i][j] * arrB[i][j];
        }
    }

    // メモリに書き込む
    volatile uint32_t *p = (volatile uint32_t *)0x200;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            *p++ = mul[i][j];
        }
    }

    // 終了マークをメモリに書き込む
    volatile uint32_t *p2 = (volatile uint32_t *)(uintptr_t)TARGET_ADDR;
    *p2 = 0xDEADBEEF;

    // 無限ループ
    while (1) {}

    return 0;
}

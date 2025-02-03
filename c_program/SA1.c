#include <stdint.h>  // uint32_t 型を使うために必要

#define TARGET_ADDR  0x150
#define UART_ADDR    0x4F0
#define DMA_ADDR     0x400  

// 固定アドレスでメモリを確保する方法
volatile uint32_t sum[4][4];

int _start(void)
{
    // 書き込み元の4x4行列
    volatile uint8_t arrA[4][4] = {
        {1, 34, 51, 68},
        {5, 12, 19, 16},
        {3, 17, 7, 4},
        {21, 38, 25, 0}
    };

    volatile uint8_t arrB[4][4] = {
        {1, 3, 154, 11},
        {18, 205, 22, 39},
        {20, 25, 25, 55},
        {15, 25, 25, 17}
    };

    // sumの内容を初期化または計算
    /*
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            //sum[i][j] = i * 4 + j; // デモ用の値
            sum[i][j] = arrA[i][j] + arrB[i][j];
        }
    }

    // メモリに書き込む
    volatile uint32_t *p = (volatile uint32_t *)TARGET_ADDR;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            *p++ = sum[i][j];
        }
    }
    */
    volatile uint32_t *p = (volatile uint32_t *)TARGET_ADDR;

    // 終了マークをメモリに書き込む
    volatile uint32_t *p2 = (volatile uint32_t *)(uintptr_t)UART_ADDR;
    *p2 = 0x02;

    *p2 = 0x04;

    *p2 = 0x06;
    *p2 = 0x01;
    *p = 0x00;

    *p2 = 0x02;
    *p = 0x00;

    *p2 = 0x03;
    *p = 0x00;

    *p2 = 0x04;
    *p = 0x00;

    // 指定アドレスのデータを読み取る
    volatile uint32_t *read_ptr = (volatile uint32_t *)DMA_ADDR;
    uint32_t read_data = *read_ptr;

    // 読み取ったデータをUARTに送信
    volatile uint32_t *p3 = (volatile uint32_t *)(uintptr_t) 0x280;
    *p3 = read_data;

    // 無限ループ
    while (1) {}

    return 0;
}

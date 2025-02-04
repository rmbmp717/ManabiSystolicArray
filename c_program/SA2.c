#include <stdint.h>  // uint32_t 型を使うために必要

#define TARGET_ADDR  0x250
#define UART_ADDR    0x4F0
#define DMA_ADDR     0x400  

#define RIGHT_SHIFT     0xFF
#define B_DATA_SHIFT    0xFE
#define BOTTOM_SHIFT    0xFD
#define A_DATA_IN       0xFC
#define B_DATA_IN       0xFB

#define DATA_OUT_ADDR   0x300

// 固定アドレスでメモリを確保する方法
volatile uint32_t sum[4][4];

int _start(void)
{
    // 書き込み元の4x4行列
    volatile uint8_t arrA[4][4] = {
        {1, 3, 5, 8},
        {5, 1, 1, 6},
        {3, 1, 7, 4},
        {1, 3, 2, 0}
    };

    volatile uint8_t arrB[4][4] = {
        {1, 3, 4, 1},
        {8, 5, 2, 3},
        {2, 2, 5, 1},
        {5, 5, 5, 7}
    };

    volatile uint32_t *p = (volatile uint32_t *)TARGET_ADDR;
    volatile uint32_t *p2 = (volatile uint32_t *)(uintptr_t)UART_ADDR;

    // 右シフト テスト
    *p2 = RIGHT_SHIFT;

    // 下シフト テスト
    *p2 = B_DATA_SHIFT;

    // A Matrix データ転送
    *p2 = A_DATA_IN;
    *p = 0x00;

    *p2 = 0x01;     // 1 data
    *p = 0x00;
    *p2 = 0x01;     // 2 data
    *p = 0x00;
    *p2 = 0x01;     // 3 data
    *p = 0x00;
    *p2 = 0x01;     // 4 data
    *p = 0x00;

    // B Matrix データ転送
    for (int j = 0; j < 4; j++) {
        *p2 = B_DATA_IN;
        *p = 0x00;
        for (int i = 0; i < 4; i++) {
            *p2 = arrB[3-j][i];   
            *p = 0x00;
        }
        *p2 = B_DATA_SHIFT;
        *p = 0x00;
    }

    // 右シフト x 4
    for (int i = 0; i < 4; i++) {
        *p2 = RIGHT_SHIFT;
        *p = 0x00;
    }

    // 下シフト x 4
    for (int i = 0; i < 4; i++) {
        *p2 = BOTTOM_SHIFT;
        *p = 0x00;
    }

    // wait
    for (int i = 0; i < 20; i++) {
        *p = 0x00;
    }

    // DMAのデータを読み取る
    volatile uint32_t *read_ptr = (volatile uint32_t *)DMA_ADDR;
    uint32_t read_data = *read_ptr;

    // 読み取ったデータをDATA_OUT_ADDRに書き込む
    volatile uint32_t *p3 = (volatile uint32_t *)(uintptr_t) DATA_OUT_ADDR;
    *p3 = read_data;

    // 無限ループ
    while (1) {}

    return 0;
}

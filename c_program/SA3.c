#include <stdint.h>  // uint32_t 型を使うために必要

#define TARGET_ADDR  0x250
#define UART_ADDR    0x4F0
#define DMA_ADDR0    0x400  
#define DMA_ADDR1    0x404  

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
    // 書き込むアドレス
    volatile uint32_t *p = (volatile uint32_t *)TARGET_ADDR;
    volatile uint32_t *p2 = (volatile uint32_t *)(uintptr_t)UART_ADDR;

    // 書き込み元の4x4行列
    volatile uint8_t arrDummy[4][4] = {         // 現状、Dummpyの位置のば配列は読み込めない
        {1, 1, 1, 1},
        {1, 1, 1, 1},
        {1, 1, 1, 1},
        {1, 1, 1, 1}
    };

    volatile uint8_t arrB[4][4] = {
        {1, 3, 4, 1},
        {8, 5, 2, 3},
        {2, 2, 5, 1},
        {5, 1, 2, 7}
    };

    volatile uint8_t arrA[4][4] = {
        {1, 1, 1, 1},
        {1, 4, 1, 1},
        {1, 1, 1, 0},
        {2, 1, 1, 1}
    };

    // 右シフト テスト
    *p2 = RIGHT_SHIFT;
    *p = 0x00;

    // 下シフト テスト
    *p2 = B_DATA_SHIFT;
    *p = 0x00;

    // A Matrix データ転送
    for (int j = 0; j < 4; j++) {
        *p2 = A_DATA_IN;
        *p = 0x00;
        for (int i = 0; i < 4; i++) {
            *p2 = arrA[i][3-j] % 256;   
            *p = 0x00;
            *p2 = 0;
            *p = 0x00;
        }
        *p2 = RIGHT_SHIFT;
        *p = 0x00;
    }


    // B Matrix データ転送
    for (int j = 0; j < 4; j++) {
        *p2 = B_DATA_IN;
        *p = 0x00;
        for (int i = 0; i < 4; i++) {
            *p2 = arrB[3-j][i] % 256;   
            *p = 0x00;
            *p2 = 0;
            *p = 0x00;
        }
        *p2 = B_DATA_SHIFT;
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
    volatile uint32_t *read_ptr0 = (volatile uint32_t *)DMA_ADDR0;
    uint32_t read_data0 = *read_ptr0;
    volatile uint32_t *read_ptr1 = (volatile uint32_t *)DMA_ADDR1;
    uint32_t read_data1 = *read_ptr1;

    // 読み取ったデータをDATA_OUT_ADDRに書き込む
    volatile uint32_t *p3 = (volatile uint32_t *)(uintptr_t) DATA_OUT_ADDR;
    *p3 = read_data0;
    volatile uint32_t *p4 = (volatile uint32_t *)(uintptr_t) DATA_OUT_ADDR + 4;
    *p4 = read_data1;

    // 無限ループ
    while (1) {}

    return 0;
}

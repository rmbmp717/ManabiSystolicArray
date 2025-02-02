#include <stdint.h>  // for uintptr_t

// RAMとして使える領域を想定
#define TARGET_ADDR  0x140

int _start(void) 
{
    // 書き込み元の2x2配列(好きな値を入れてOK)をマクロで初期化
    volatile uint32_t arr[2][2];

    arr[0][0] = 0x11111133;
    arr[0][1] = 0x22222222;
    arr[1][0] = 0x33333333;
    arr[1][1] = 0x44444444;

    // 一度、配列の要素をローカル変数にコピー
    uint32_t a = arr[0][0];  // 0x11111111
    uint32_t b = arr[0][1];  // 0x22222222
    uint32_t c = arr[1][0];  // 0x33333333
    uint32_t d = arr[1][1];  // 0x44444444

    // (参考) 別アドレスへも何か書いてみる例
    *(volatile uint32_t *)0x110 = 0xDEADBEEF;
    *(volatile uint32_t *)0x120 = 0x11ADBEE9;

    // メモリ書き込み先アドレス(ここでは 0x80)を指すポインタを作成
    //volatile uint32_t *p = (volatile uint32_t *)(uintptr_t)TARGET_ADDR;

    // コピーした変数を順番に書き込む
    *(volatile uint32_t *)0x140 = a;
    *(volatile uint32_t *)0x150 = b;
    *(volatile uint32_t *)0x160 = c;
    *(volatile uint32_t *)0x170 = d;
    *(volatile uint32_t *)0x180 = 0x33ADBEEF;

    // 無限ループに入る（実行終了させない）
    while (1) {
        // ここでは何もしない
    }

    // 実際には到達しない
    return 0;
}

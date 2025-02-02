MEMORY {
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 0x00001000
    RAM (rw) : ORIGIN = 0x00000200, LENGTH = 0x00001000
}

/* スタックサイズを仮に 0x1000(=4KB) とする例 */
STACK_SIZE = 0x1000;

SECTIONS {

    .text : {
        *(.text)
        /* ほかに .rodata 等あれば追記 */
    } > ROM

    .data : {
        *(.data)
    } > RAM

    .bss : {
        *(.bss)
        *(COMMON)
    } > RAM

    /* スタック領域を定義 */
    .stack (NOLOAD) : ALIGN(8) {
        _stack_top = . + STACK_SIZE;
        _stack_end = .;
    } > RAM
}

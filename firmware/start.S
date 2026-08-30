    .section .text.start, "ax", @progbits
    .globl _start
    .type _start, @function
_start:
    li sp, 0x00010000
    call main
1:
    j 1b
    .size _start, .-_start

.nolist
.include "m1280def.inc"
.list

.equ tmp, 0x10

.section .text
.org 0x0000
    jmp     main
.org UTXC3addr * 2 + 2


main:
    sbi     PORTA, 0
    ldi     tmp, 0xff
    out     DDRA, tmp
    ldi     tmp, 0x01
main_loop:
    sleep
    rol     tmp
    out     PORTA, tmp
    rjmp    main_loop

.nolist
.include "m1280def.inc"
.list

.equ PORT, PORTA
.equ DDR, DDRA
.equ PIN, PINA

.equ temp, 0x10
.equ pa1, 0x11
.equ pa2, 0x12
.equ pa3, 0x13

.section .text
.globl main
.org 0x0000

    rjmp    main

main:
main_init_stack_ptr:
    ldi     temp, lo8(RAMEND)
    out     SPL, temp
    ldi     temp, hi8(RAMEND)
    out     SPH, temp

main_init_ports:
    ldi     temp, 0x0
    out     PORT, temp
    ldi     temp, 0xf0          ; 7654 3210 (PORTA index)
    out     DDR, temp           ; oooo iiii (i/o state)

main_loop:
    in      temp, PIN
    andi    temp, 0x0f

    rcall   set_led0
    rcall   set_led1
    rcall   set_led2
    rcall   set_led3

    out     PORT, temp

    rjmp    main_loop

set_led0:                       ; PORT << 4: (1 & 2) | 3
    rcall   prepare_operands

    and     pa1, pa2
    or      pa3, pa1

    sbrs    pa3, 0
    ret
    sbr     temp, 0b00010000
    ret

set_led1:                       ; PORT << 5: (1 | !2) & 3
    rcall   prepare_operands

    com     pa2
    or      pa1, pa2
    and     pa3, pa1

    sbrs    pa3, 0
    ret
    sbr     temp, 0b00100000
    ret

set_led2:                       ; PORT << 6: (1 xor 2)
    rcall   prepare_operands

    eor     pa1, pa2

    sbrs    pa1, 0
    ret
    sbr     temp, 0b01000000
    ret

set_led3:                       ; PORT << 7: (1 == 2)
    rcall   prepare_operands

    cpse    pa1, pa2
    ret
    sbr     temp, 0b10000000
    ret

prepare_operands:               ; move inputs 1..3 to pa1..3
    mov     pa1, temp           ; and shift/mask them the LSB
    mov     pa2, temp
    mov     pa3, temp
    lsr     pa1
    lsr     pa2
    lsr     pa2
    lsr     pa3
    lsr     pa3
    lsr     pa3
    andi    pa1, 0x01
    andi    pa2, 0x01
    andi    pa3, 0x01
    ret
    

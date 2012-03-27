.nolist
.include "m1280def.inc"
.list

.equ tmp, 0x10

.section .text
.globl main
.org 0x0000

    rjmp    main

main:
main_init_stack_ptr:
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp

main_init_ports:
    ldi     tmp, 1 << DDA3
    out     DDRA, tmp

    ldi     tmp, 0xff
    out     DDRB, tmp
    out     DDRC, tmp
    out     DDRD, tmp

    sbi     PORTA, PA3

    in      r1, PINA
    in      r2, PINA
    in      r3, PINA

    out     PORTB, r1
    out     PORTC, r2
    out     PORTD, r3

main_loop:
    sleep



wait:
    clr     tmp

wait_outer_loop:
    push    tmp
    clr     tmp

wait_inner_loop:
.rept 32
    nop
.endr

    dec     tmp
    brne    wait_inner_loop

    pop     tmp
    dec     tmp
    brne    wait_outer_loop

    ret

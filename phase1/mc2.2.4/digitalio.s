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
    ldi     tmp, 0x00

    ; all ports to input

    out     DDRA, tmp
    out     DDRB, tmp
    out     DDRC, tmp
    out     DDRD, tmp
    out     DDRE, tmp
    out     DDRF, tmp
    out     DDRG, tmp

main_loop:
    in      tmp, PINA

    cpi     tmp, 0xff
    brne    main_write_out
    ldi     tmp, 0x00

main_write_out:
    out     DDRA, tmp
    out     PORTA, tmp

    rjmp    main_loop



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

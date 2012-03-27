.nolist
.include "m1280def.inc"
.list

.equ temp, 0x10
.equ temp2, 0x11

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
    ldi     temp, 0x0f
    ldi     temp2, 0xff

    out     PORTA, temp
    ldi     temp, 0x0
    out     DDRA, temp

    out     PORTB, temp
    out     DDRB, temp2

    out     PORTC, temp
    out     DDRC, temp2

main_loop:
    in      temp, PINA
    out     PORTC, temp

    in      temp, PORTA
    out     PORTB, temp

    rjmp    main_loop

.nolist
.include "m1280def.inc"
.list

.equ tmp, 0x10
.equ cnt1, 0x11
.equ cnt2, 0x12

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
    ldi     tmp, 0xff

    ; all ports to output

    out     DDRA, tmp
    out     DDRB, tmp
    out     DDRC, tmp
    out     DDRD, tmp
    out     DDRE, tmp
    out     DDRF, tmp
    out     DDRG, tmp

main_init_misc:
    clr     cnt1
    clr     cnt2

main_loop:

    ; update counters

    inc     cnt1
    subi    cnt2, 0x3

    ; PORTA

    mov     tmp, cnt1
    eor     tmp, cnt2
    out     PORTA, tmp

    ; PORTB

    mov     tmp, cnt1
    com     tmp
    add     tmp, cnt2
    out     PORTB, tmp

    ; PORTC

    mov     tmp, cnt1
    sub     tmp, cnt2
    out     PORTC, tmp

    ; PORTD

    mov     tmp, cnt2
    neg     tmp
    and     tmp, cnt1
    out     PORTD, tmp

    ; PORTE

    mov     tmp, cnt1
    mul     tmp, cnt2
    out     PORTE, tmp

    ; PORTF

    mov     tmp, cnt1
    lsr     tmp
    or      tmp, cnt2
    out     PORTF, tmp

    ; PORTG

    mov     tmp, cnt1
    swap    tmp
    andi    tmp, 0x0f
    andi    cnt2, 0xf0
    or      tmp, cnt2
    out     PORTG, tmp


    call    wait

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

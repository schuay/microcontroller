.nolist
.include "m1280def.inc"
.list

.equ tmp, 0x10
.equ cnt, 0x11
.equ led, 0x12

.section .text
.globl main
.org 0x0000
    rjmp    main
.org INT0addr * 2   ; PD0
    rjmp isr0
.org INT1addr * 2   ; PD1
    rjmp isr1

main:
main_init_stack_ptr:
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp

main_init_ports:
    ldi     tmp, 0xff
    out     DDRA, tmp

    ldi     tmp, 0xff
    out     DDRB, tmp

    ldi     tmp, 0x00
    out     DDRD, tmp
    ldi     tmp, 0b00000011
    out     PORTD, tmp

main_init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

main_init_interrupts:
    lds     tmp, EICRA
    ori     tmp, (1 << ISC01) | (1 << ISC11)
    sts     EICRA, tmp

    in      tmp, EIMSK
    ori     tmp, (1 << INT0) | (1 << INT1)
    out     EIMSK, tmp

    sei
 
main_init_misc:
    ldi     cnt, 0x00
    ldi     led, 1 << PA0
    out     PORTA, led

main_loop:
    inc     cnt
    out     PORTB, cnt

    sleep
    rjmp    main_loop


isr0:       ; rotate lower nibble of leds left
    lsl     led

    ldi     tmp, 0x0f
    and     tmp, led
    tst     tmp
    brne    isr0_set_led
    swap    led

isr0_set_led:
    out     PORTA, led
    reti


isr1:       ; rotate lower nibble of leds right
    lsr     led

    ldi     tmp, 0x0f
    and     tmp, led
    tst     tmp
    brne    isr1_set_led
    ldi     led, 0b00001000

isr1_set_led:
    out     PORTA, led
    reti


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

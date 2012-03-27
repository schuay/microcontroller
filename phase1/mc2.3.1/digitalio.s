.nolist
.include "m1280def.inc"
.list

.equ BAUD_RATE, 103 ; 9600

.equ tmp, 0x10

.section .text
.org 0x0000
    jmp     main
.org URXC0addr * 2
    jmp     isr_urxc0


main:
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp

    call    init

main_loop:
    sleep
    rjmp    main_loop


isr_urxc0:
    lds     tmp, UDR0
    out     PORTA, tmp

    sts     UDR0, tmp

    reti


init:
init_ports:
    ldi     tmp, 0xff
    out     DDRA, tmp

init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

init_usart:
    ldi     tmp, 1 << RXEN0 | 1 << TXEN0 | 1 << RXCIE0
    sts     UCSR0B, tmp

    ldi     tmp, hi8(103)
    sts     UBRR0H, tmp
    ldi     tmp, lo8(103)
    sts     UBRR0L, tmp

init_misc:

    sei
    
    ret

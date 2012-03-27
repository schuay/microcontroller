.nolist
.include "m1280def.inc"
.list

.equ tmp, 16
.equ index, 17
.equ valueh, 18
.equ valuel, 19
.equ param1, 24
.equ param2, 25
.equ param3, 26

.section .text
.org 0x0000
    jmp     main
.org INT7addr * 2
    jmp     isr_int7

main:
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp

    call    init
    
main_loop:
    ldi     param1, 0 | 0 << 7
    mov     param2, index
    ldi     param3, 0x00
    call    dispUint16
    
    ldi     param1, 0 | 1 << 7
    mov     param2, valuel
    mov     param3, valueh
    call    dispUint16

    sleep

    rjmp    main_loop

; ----------------------------
; fibonacci nrs
; arg1 (top of stack): 16 bit index of fib nr
; return value (top of stack): 16 bit fib nr
; ----------------------------

.equ LAST_32B_FIB_INDEX, 24

.equ OFF_ARG_LO, 5 + 2 + 1
.equ OFF_ARG_HI, 5 + 2 + 1 + 1

fibonacci:
    push    ZL
    push    ZH
    push    YL
    push    YH
    push    tmp

    in      YL, SPL
    in      YH, SPH

    ldd     ZL, Y + OFF_ARG_LO
    ldd     ZH, Y + OFF_ARG_HI

    cpi     ZL, LAST_32B_FIB_INDEX + 1
    brsh    fibonacci_out

    tst     ZH
    brne    fibonacci_recurse_a

    cpi     ZL, 0x01 + 1            ; index <- {0, 1}: value = index
    brlo    fibonacci_out

fibonacci_recurse_a:
    sbiw    ZL, 0x01

    push    ZH
    push    ZL

    call    fibonacci

fibonacci_recurse_b:
    sbiw    ZL, 0x01

    push    ZH
    push    ZL

    call    fibonacci

fibonacci_sum:
    pop     ZL                      ; return value b
    pop     ZH

ldi     tmp, 0xff
out     DDRA, tmp
out     DDRB, tmp
out     DDRF, tmp
out     DDRG, tmp
out     PORTA, ZL
out     PORTB, ZH

    pop     tmp                     ; return value a LOW
    add     ZL, tmp

out     PORTF, tmp

    pop     tmp                     ; return value a HIGH
    adc     ZH, tmp

out     PORTG, tmp

    std     Y + OFF_ARG_HI, ZH
    std     Y + OFF_ARG_LO, ZL

fibonacci_out:
    pop     tmp
    pop     YH
    pop     YL
    pop     ZH
    pop     ZL

    ret


; ----------------------------
; int7 handler
; ----------------------------

isr_int7:
    push    tmp
    in      tmp, SREG
    push    tmp

    inc     index

    ldi     tmp, 0x00
    push    tmp
    push    index

    call    fibonacci

    pop     valuel
    pop     valueh

    pop     tmp
    out     SREG, tmp
    pop     tmp

    reti

; ----------------------------
; init board
; ----------------------------

init:
init_ports:
    ldi     tmp, 1 << PE7
    out     PORTE, tmp
    
init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

init_interrupts:
    ldi     tmp, 1 << ISC71
    sts     EICRB, tmp

    ldi     tmp, 1 << INT7
    out     EIMSK, tmp

init_lcd:
    call    initLCD

init_misc:
    ldi     index, 0x00
    ldi     valuel, 0x00
    ldi     valueh, 0x00

    sei

    ret

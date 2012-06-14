.nolist
.include "m1280def.inc"
.list

.equ zero, 0x12
.equ tmp, 0x11
.equ a, 0x10
.equ n, 5

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

    out     DDRA, tmp
    out     DDRB, tmp
    out     DDRC, tmp
    out     DDRD, tmp
    out     DDRE, tmp
    out     DDRF, tmp

main_init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

main_init_misc:
    ldi     zero, 0x00

    call    main_div_truncate
    call    main_div_round_up
    call    main_div_round_to_nearest

    call    main_big_div_truncate
    call    main_big_div_round_up
    call    main_big_div_round_to_nearest

main_loop:
    sleep
    rjmp    main_loop

; Initialize a to 35
reset_a:
    ldi     a, 35
    ret

; 2.a)
; Calculate a / 2^n (truncated).
; The upper bound for the number of cycles is n.

main_div_truncate:
    call    reset_a

    .rept n
    asr     a           ; n cycles
    .endr

    out     PORTA, a
    ret

; 2.b)
; Calculate a / 2^n (rounded up).
; The upper bound for the number of cycles is n + 2.

main_div_round_up:
    call    reset_a

    dec     a           ; 1 cycle
    .rept n
    asr     a           ; n cycles
    .endr
    inc     a           ; 1 cycle

    out     PORTB, a
    ret

; 2.c)
; Calculate a / 2^n (round to nearest).
; The upper bound for the number of cycles is n + 1.

main_div_round_to_nearest:
    call    reset_a

    .rept n
    asr     a           ; n cycles
    .endr

    adc     a, zero     ; 1 cycle

    out     PORTC, a
    ret

; 3.a)
; Calculate a / 2^n (truncated).
; a is now stored across R different general purpose registers starting at r1.
; The upper bound for the number of cycles is TODO.

main_big_div_truncate:
    call    reset_a

    ; Algorithm idea:
    ; Calculate p = n % 8 and q = n / 8.
    ; Shift entire registers by q (for example, move reg 8 to reg 5).
    ; Shift remaining registers by p, making sure to move LSB from reg i+1 to
    ; MSB in reg i.

    .rept n
    asr     a           ; n cycles
    .endr

    out     PORTD, a
    ret

main_big_div_round_up:
    ret

main_big_div_round_to_nearest:
    ret

.nolist
.include "m1280def.inc"
.list

.equ zero, 0x10
.equ tmp, 0x11
.equ mask, 0x12
.equ sign, 0x13
.equ a, 0x01

.equ n, 5
.equ mod8, n % 8
.equ div8, n / 8

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
    ldi     sign, 0x00
    ldi     mask, 0b01111111

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
    ldi     tmp, 35
    mov     a, tmp
    ret

reset_big_a:
    ldi     tmp, 35
    mov     a, tmp
    .irpc   param,8765432
    mov     0x0\param, zero
    .endr
    ret

; =============================================================================
; 2.a)
; Calculate a / 2^n (truncated).
; The upper bound for the number of cycles is n.

main_div_truncate:
    call    reset_a

    .rept n

    ; To divide a by 2^n (truncating the results), perform a right shift n
    ; times. The sign bit is preserved by using an the arithmetic shift.

    asr     a           ; n cycles
    .endr

    out     PORTA, a
    ret

; =============================================================================
; 2.b)
; Calculate a / 2^n (rounded up).
; The upper bound for the number of cycles is n + 2.

main_div_round_up:
    call    reset_a

    ; To round up instead of down, the algorithm from 2.a needs to be altered.
    ; When a is not evenly divisible by 2^n, the result is
    ;
    ; div_truncate(a, n) + 1
    ;
    ; This is achieved by incrementing the final result (inc a).
    ;
    ; The only remaining problem is that this produces incorrect results for
    ; a = m * 2^n, in which case div_round_up(a, n) should equal m. This
    ; issue can be solved by decrementing a before shifting (dec a).

    dec     a           ; 1 cycle
    .rept n
    asr     a           ; n cycles
    .endr
    inc     a           ; 1 cycle

    out     PORTB, a
    ret

; =============================================================================
; 2.c)
; Calculate a / 2^n (round to nearest).
; The upper bound for the number of cycles is n + 1.

main_div_round_to_nearest:
    call    reset_a

    ; Again, the algorithm is very similar to div_truncate(a, n).
    ; The round to nearest effect is achieved by truncating if
    ; a / 2^n < 1/2 and rounding up otherwise.
    ; We can determine this by looking at the carry flag after the last
    ; shift. It is clear if and only if a / 2^n < 1/2.
    ; Adjust the final result by performing an add with carry (result, zero),
    ; which adds one to the result if the carry flag is set.

    .rept n
    asr     a           ; n cycles
    .endr

    adc     a, zero     ; 1 cycle

    out     PORTC, a
    ret

; =============================================================================
; 3.a)
; Calculate a / 2^n (truncated).
; a is now stored across R different general purpose registers starting at r1.
; The upper bound for the number of cycles is 9 * R.

main_big_div_truncate:
    call    reset_big_a
    call    big_div_truncate
    out     PORTD, a
    ret

big_div_truncate:

    ; The general algorithm idea:
    ;
    ; Calculate mod8 = n % 8 and div8 = n / 8.
    ; First move all registers div places to the right (for example,
    ; move reg_4 to reg_1 with div = 3).
    ; Then perform internal shifts by mod on all registers.
    ;
    ; For the sake of simplicity, set R = 8. a is stored in r1 (LSB) to r8
    ; (MSB). It is trivial to alter the algorithm to different R's, but
    ; readability is improved by using the .irpc assembler directive.

    ; Register move div8 times.
    ; Only perform register move if there is something to do.

    .if     div8 != 0

    ; After moving registers over, the tail registers need to be cleared to
    ; 0xFF (for negative numbers) or 0x00 (otherwise). Prepare a register with
    ; the appropriate value so we can copy it over easily later.

    sbrc    0x08    ; 1 cycles if n non-negative, 2 otherwise
    com     sign    ; 1 cycle

    ; for (param = div8 + 1; param <= R; param++)

    .irpc   param,12345678
    .if     \param > div8

    mov     0x0\param - div8, 0x0\param ; Exactly (R - div8 - 1) cycles. At most R - 1 cycles.

    ; Clear moved register to sign bits (see above).
    mov     0x0\param, sign ; Exactly (R - div8 - 1) cycles. At most R - 1 cycles.

    .endif  ; \param > div8
    .endr   ; .irpc param, 1..R

    .endif  ; div8 != 0

    ; Register shift mod8 times.

    .rept   mod8

    ; for (param = R - div8; param > 0; param++)

    .irpc   param,87654321
    .if     \param <= 8 - div8
    
    .if     \param == 8 - div8

    ; Shifting reg_{R - div8} ignores the carry flag and respects the sign bit.
    asr     0x0\param ; Ignored for cycle count, see ror below.

    .else

    ror     0x0\param ; Exactly mod8 * (R - div8) cycles. At most 7 * R.

    .endif  ; \param == R

    .endif  ; \param <= R - div8
    .endr   ; .irpc param, R..1

    .endr   ; .rept mod8

    ; Summing up, we have exactly:
    ;
    ; 2                 Prepare sign register (only if div8 != 0)
    ; R - div8 - 1      Register move (only if div8 != 0)
    ; R - div8 - 1      Register clear to sign (this could be optimized further)
    ; mod8 * (R - div8) Register shift
    ; --------------------------------
    ; mod8 * (R - div8) 
    ; +  2 * (R - div8 + - 1) + 2 (if div8 != 0).
    ;
    ; and at most:
    ;
    ; 2
    ; R - 1
    ; R - 1
    ; 7 * R
    ; --------------------------------
    ; 9 * R cycles.
    ;
    ; div8 = n / 8
    ; mod8 = n % 8

    ret

; Adds reg_tmp to the number represented by registers 1..R (R is assumed to be 8)
; The upper bound for used cycles is R.
big_add:
    add     0x01, tmp ; 1 cycle
    .irpc   param,2345678
    adc     0x0\param, zero ; 7 cycles
    .endr

    ret

; Subtracts reg_tmp to the number represented by registers 1..R (R is assumed to be 8)
; The upper bound for used cycles is R.
big_sub:
    sub     r1, tmp ; 1 cycle
    .irpc   param,2345678
    sbc     r\param, zero ; 7 cycles
    .endr

    ret

; =============================================================================
; 3.b)
; Calculate a / 2^n (rounded up).
; a is now stored across R different general purpose registers starting at r1.
; The upper bound for the number of cycles is 11 * R + 2.

main_big_div_round_up:
    call    reset_big_a

    ldi     tmp, 1 ; 1 cycle
    call    big_sub ; R cycles

    call    big_div_truncate ; At most 9 * R cycles

    ldi     tmp, 1 ; 1 cycle
    call    big_add ; R cycles

    out     PORTE, a
    ret

; =============================================================================
; 3.c)
; Calculate a / 2^n (round to nearest).
; a is now stored across R different general purpose registers starting at r1.
; The upper bound for the number of cycles is TODO.

main_big_div_round_to_nearest:
    call    reset_big_a
    out     PORTF, a
    ret

.nolist
.include "m1280def.inc"
.list

.equ TOP, 1 << 7
.equ DATA_START, SRAM_START

.equ tmp, 0x10
.equ n, 0x11
.equ param1, 24
.equ param2, 25
.equ param3, 26

.section .text
.org 0x0000
    jmp     main
.org INT0addr * 2
    jmp     isr_int0
.org INT1addr * 2
    jmp     isr_int1


main:
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp

    call    init

main_loop:
    ldi     param1, 0 | (0 << 7)
    mov     param2, n
    ldi     param3, 0x00
    call    dispUint16

    sleep
    rjmp    main_loop


sieve:
    ldi     param1, 0x02

sieve_loop:
    push    param1
    call    sieve_unmark_multiples
    pop     param1

    call    next_n
    cpi     param1, TOP
    brlo    sieve_loop

    ret


; takes base factor in param1
sieve_unmark_multiples:
    push    n

    mov     n, param1           ; n stores base factor
    lsl     param1              ; first unmarked member is n * 2
    brvs    sieve_unmark_multiples_out
    cpi     param1, TOP
    brsh    sieve_unmark_multiples_out
    mov     param2, 0x00

sieve_unmark_multiples_loop:
    call    set_array

    add     param1, n
    brvs    sieve_unmark_multiples_out

    cpi     param1, TOP
    brlo    sieve_unmark_multiples_loop

sieve_unmark_multiples_out:
    pop     n
    ret


; takes current n in param1
; returns next n in param1
next_n:
    push    n

    mov     n, param1

next_n_loop:
    inc     n
    brvs    next_n_out

    cpi     n, TOP
    brsh    next_n_out

    mov     param1, n
    call    get_array

    sbrs    param1, 0
    rjmp    next_n_loop

next_n_out:
    mov     param1, n

    pop     n
    ret


isr_int0:
    push    tmp
    in      tmp, SREG
    push    tmp
    push    param1

    mov     param1, n
    call    next_n
    mov     n, param1

    pop     param1
    pop     tmp
    out     SREG, tmp
    pop     tmp

    reti

isr_int1:
    reti


; takes array position in param1
; sets Y and exits
init_array_ptr:
    push    tmp

    ldi     YH, hi8(DATA_START)
    ldi     YL, lo8(DATA_START)
    
    ldi     tmp, 0x00
    add     YL, param1
    adc     YH, tmp             ; Y is now pointing at the current member

    pop     tmp

    ret


; takes array position in param1
; and value in param2
set_array:
    push    YL
    push    YH

    call    init_array_ptr
    st      Y, param2

    pop     YH
    pop     YL

    ret


; takes array position in param1
; returns value in param1
get_array:
    push    YL
    push    YH

    call    init_array_ptr
    ld      param1, Y

    pop     YH
    pop     YL

    ret


init:
init_ports:
    ldi     tmp, 0xff
    out     DDRB, tmp

    ldi     tmp, 0x00
    out     DDRD, tmp

    ldi     tmp, 1 << PD0 | 1 << PD1
    out     PORTD, tmp
    
init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

init_interrupts:
    ldi     tmp, 1 << ISC01 | 1 << ISC11
    sts     EICRA, tmp

    ldi     tmp, 1 << INT0 | 1 << INT1
    out     EIMSK, tmp

init_array:
    ldi     param1, TOP
    ldi     param2, 0x01
    
init_array_loop:                ; init array members to 0x01 (= marked)
    call    set_array
    dec     param1
    brne    init_array_loop

    sei
    call    sieve

init_misc:
    call    initLCD
    ldi     n, 0x01

init_out:
    ret

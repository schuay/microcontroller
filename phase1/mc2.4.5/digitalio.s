.nolist
.include "m1280def.inc"
.list

.equ START, 3

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


main:
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp

    call    init

main_loop:
    call    print_n
    sleep
    rjmp    main_loop


print_n:
    ldi     param1, 0 | (0 << 7)
    mov     param2, n
    ldi     param3, 0x00
    call    dispUint16

    ret


next_n:
    push    tmp

    sbrs    n, 0
    rjmp    next_n_even

next_n_odd:
    mov     tmp, n
    lsl     n           ; n = n_old * 2
    add     n, tmp      ; n = n_old * 3
    inc     n           ; n = n_old * 3 + 1

    rjmp    next_n_out

next_n_even:
    lsr     n

next_n_out:
    pop     tmp
    ret


isr_int0:
    push    tmp
    in      tmp, SREG
    push    tmp

    call    next_n

    pop     tmp
    out     SREG, tmp
    pop     tmp

    reti


init:
init_ports:
    ldi     tmp, 0x00
    out     DDRD, tmp

    ldi     tmp, 1 << PD0
    out     PORTD, tmp
    
init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

init_interrupts:
    ldi     tmp, 1 << ISC01
    sts     EICRA, tmp

    ldi     tmp, 1 << INT0
    out     EIMSK, tmp

init_misc:
    ldi     n, START
    
    call    initLCD

init_out:
    sei
    ret

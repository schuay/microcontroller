.nolist
.include "m1280def.inc"
.list

.equ DELAY, 1250        ; 50 Hz with 16 MHz clock and 256x prescaler
.equ MEM_OFFS, 0x20
.equ PORT_OFFS, 0x02    ; offset from PINx to PORTx
.equ LED_OFFS, 0x03     ; offset from PINx to PINx+1

.equ tmp, 0x10

.section .text
.globl main
.org 0x0000
    rjmp    main
.org INT0addr * 2
    rjmp    isr_int0
.org OC1Aaddr * 2
    rjmp    isr_oc1a


main:
main_init_stack_ptr:
    ldi     tmp, lo8(RAMEND)
    out     SPL, tmp
    ldi     tmp, hi8(RAMEND)
    out     SPH, tmp

    call    init

main_loop:
    sleep
    rjmp    main_loop
    
; -----------------------------------------

isr_int0:
    push    tmp
    in      tmp, SREG
    push    tmp

    pop     tmp
    out     SREG, tmp
    pop     tmp
    reti

; -----------------------------------------

isr_oc1a:
    push    tmp
    in      tmp, SREG
    push    tmp

    ld      tmp, Y    ; load PINx
    inc     tmp
    std     Y + PORT_OFFS, tmp

    cpi     YL, PING + MEM_OFFS
    brne    isr_oc1a_not_lower_boundary
    ldi     YH, hi8(PINH)
    ldi     YL, lo8(PINH)
    rjmp    isr_oc1a_out

isr_oc1a_not_lower_boundary:
    cpi     YH, hi8(PINL)
    brne    isr_oc1a_not_upper_boundary
    cpi     YL, lo8(PINL)
    brne    isr_oc1a_not_upper_boundary
    clr     YH
    ldi     YL, PINA + MEM_OFFS
    rjmp    isr_oc1a_out

isr_oc1a_not_upper_boundary:
    adiw    YL, LED_OFFS

isr_oc1a_out:
    pop     tmp
    out     SREG, tmp
    pop     tmp
    reti

; -----------------------------------------

init:
init_ports:
    ldi     tmp, 0xff

    clr     YH
    ldi     YL, DDRA + MEM_OFFS             ; 0x20 is memory offset (because of st)

init_ports_loop:
    st      Y, tmp
    subi    YL, -LED_OFFS
    cpi     YL, DDRG + MEM_OFFS + 1         ; offset + 1 so we can use < instead of <=
    brlo    init_ports_loop

    ldi     YH, hi8(DDRH)
    ldi     YL, lo8(DDRH)

init_high_ports_loop:
    st      Y, tmp
    adiw    YL, LED_OFFS
    cpi     YL, lo8(DDRL + 1)
    brlo    init_high_ports_loop

init_sleep:
    ldi     tmp, 1 << SE
    out     SMCR, tmp

init_interrupts:
    ldi     tmp, 1 << ISC01
    sts     EICRA, tmp

    ldi     tmp, 1 << INT0
    out     EIMSK, tmp

init_timer:
    ldi     tmp, 1 << CS12 | 1 << WGM12
    sts     TCCR1B, tmp                     ; I/O clock / 256, CTC

    ldi     tmp, hi8(DELAY)
    sts     OCR1AH, tmp
    ldi     tmp, lo8(DELAY)
    sts     OCR1AL, tmp

    ldi     tmp, 1 << OCIE1A
    sts     TIMSK1, tmp
    
init_misc:

    clr     YH
    ldi     YL, PINA + MEM_OFFS

    sei

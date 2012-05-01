#define F_CPU 16000000

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "lcd.h"

/* 5 ms / (62.5 ns * 1024 prescaler) */
#define TIMER_CYCLES (78)

void setup(void) {
    TCCR1B |= _BV(CS12) | _BV(CS10) | _BV(WGM12);
    OCR1A = TIMER_CYCLES;
    TIMSK1 |= _BV(OCIE1A);

    UBRR0 = 8;
    UCSR0A = 0x00;
    UCSR0B |= _BV(RXCIE0) | _BV(UDRIE0) | _BV(RXEN0) | _BV(TXEN0);

    initLcd();
}

int main(void) {
    setup();

    sei();
    sleep_enable();

    fprintf(lcdout, "%d", 'a');

    for (;;) {
        sleep_cpu();
    }
}

ISR(USART0_RX_vect, ISR_BLOCK) {
    fprintf(lcdout, "%d", UDR0);
}

ISR(USART0_UDRE_vect, ISR_BLOCK) {
    const uint8_t pina = PINA;
    if (pina) {
        UDR0 = pina + 'a';
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    syncScreen();
}

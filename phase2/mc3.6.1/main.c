#define F_CPU 16000000

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "lcd.h"

/* 5 ms / (62.5 ns * 1024 prescaler) */
#define TIMER_CYCLES (78)

void setup(void) {
    DDRA = 0xff;

    TCCR1B |= _BV(CS12) | _BV(CS10) | _BV(WGM12);
    OCR1A = TIMER_CYCLES;
    TIMSK1 |= _BV(OCIE1A);

    UBRR0 = 8;
    UCSR0A = 0x00;
    UCSR0B |= _BV(RXCIE0) | _BV(RXEN0);

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
    uint8_t in = UDR0;
    PORTA = in;
    fprintf(lcdout, "%d", in);
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    syncScreen();
}

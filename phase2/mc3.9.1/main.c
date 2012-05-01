#define F_CPU       (16000000UL)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "lcd.h"

/* 50 ms / (62.5 ns * 1024 prescaler) */
#define TIMER_CYCLES (781)

void setup(void) {
    /* PA0:3 output, PA4:7 input with pullup. */
    DDRA = 0x0f;
    PORTA = 0xf0;

    DDRB = 0xff;

    TCCR1B |= _BV(CS12) | _BV(CS10) | _BV(WGM12);
    OCR1A = TIMER_CYCLES;
    TIMSK1 |= _BV(OCIE1A);

    TCCR4B |= _BV(CS42) | _BV(CS40) | _BV(WGM42);
    OCR4A = TIMER_CYCLES / 5;
    TIMSK4 |= _BV(OCIE4A);

    initLcd();
}

int main(void) {
    setup();

    sei();
    sleep_enable();

    for (;;) {
        sleep_cpu();
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    static uint8_t col = 0;

    uint8_t pina = (~PINA >> 4) & 0x0f;
    if (pina) {
        uint8_t row = 0;
        while (_BV(row) != pina) {
            row++;
        }
        fprintf(lcdout, "\rButton (%d, %d)", col, row);
        col = 0;
    } else {
        col = (col + 1) % 4;
    }

    PORTA = (PORTA & 0xf0) | (0x0f & ~_BV(col));
}

ISR(TIMER4_COMPA_vect, ISR_BLOCK) {
    syncScreen();
}

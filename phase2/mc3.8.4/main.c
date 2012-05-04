#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#include <stdlib.h>

#include "uart_streams.h"
#include "lcd.h"

void setup(void) {
    lcd_init();
    uart_streams_init();

    DDRA = 0xff;

    /* 1024x prescaler, ctc, 250ms */
    TCCR1B |= _BV(CS12) | _BV(CS10) | _BV(WGM12);
    TIMSK1 |= _BV(OCIE1A);
    OCR1A = 3906;

    sleep_enable();
}

int main(void) {
    setup();
    sei();

    printf("Hello\n");
    fprintf(lcdout, "Hello");

    for (;;) {
        sleep_cpu();
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    lcd_sync();
}

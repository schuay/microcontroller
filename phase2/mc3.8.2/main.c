#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>
#include <stdbool.h>

void setup(void) {
    DDRA = 0xff;
    DDRD = 0x00;
    PORTD = 0xff;

    /* no prescaler, ctc, 1 ms timer  */
    OCR1A = 16000;
    TCCR1B |= _BV(CS10) | _BV(WGM12);
    TIMSK1 |= _BV(OCIE1A);
}

int main(void) {
    setup();

    sleep_enable();
    sei();

    for (;;) {
        sleep_cpu();
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    static uint8_t low_ticks = 0;
    static bool processed = false;

    /* not pressed */
    if (PIND & _BV(PD0)) {
        low_ticks = 0;
        processed = false;
        return;
    }

    /* button press already processed */
    if (processed) {
        return;
    }

    /* pressed, not processed */
    low_ticks++;
    if (low_ticks == 50) { // pressed for 50ms without bounce
        PORTA++;
        processed = true;
    }
}

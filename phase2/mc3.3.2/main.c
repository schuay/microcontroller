#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

void setup(void) {
    DDRB = 0xff;
    PORTB = _BV(PB0);

    PORTE = _BV(PE7);

    EICRB |= _BV(ISC71);
    EIMSK |= _BV(INT7);
}

int main(void) {
    setup();

    sei();
    sleep_enable();

    for (;;) {
        sleep_cpu();
    }
}

ISR(INT7_vect, ISR_BLOCK) {
    uint8_t led = PORTB << 1;
    if (led & 0xf0) {
        led = 0x01;
    }
    PORTB = led;
}

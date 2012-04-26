#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/cpufunc.h>

void setup(void) {
    DDRH = 0xff;
    PORTH = _BV(PH3);

    TCCR4B |= _BV(CS40) | _BV(WGM42); // no prescaler, CTC mode

    // 1/16000000 * mult * prescaler = time
    // mult = time * fcpu /  prescaler 
    // mult = 25 us * 16000000 = 400
    //
    // overflow at 2^16
    // TCNT4 = 2^16 - mult = 65136
    //
    OCR4A = 400;
    TIMSK4 |= _BV(OCIE4A);
}

int main(void) {
    setup();
    sleep_enable();
    sei();

    for (;;) {
        sleep_cpu();
    }
}

ISR(TIMER4_COMPA_vect, ISR_BLOCK) {
    static uint8_t s = 1;
    s ^= 0x01;
    if (s) {
        OCR4A = 800;
    } else {
        OCR4A = 400;
    }
    PORTH ^= _BV(PH3);
}

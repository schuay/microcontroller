#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/cpufunc.h>

void setup(void) {
    DDRH = 0xff;
    PORTH = 0x00;

    TCCR4B |= _BV(CS40); // no prescaler

    // 1/16000000 * mult * prescaler = time
    // mult = time * fcpu /  prescaler 
    // mult = 25 us * 16000000 = 400
    //
    // overflow at 2^16
    // TCNT4 = 2^16 - mult = 65136
    //
    TCNT4 = 65136;
    TIMSK4 |= _BV(TOIE4);
}

int main(void) {
    setup();
    sleep_enable();
    sei();

    for (;;) {
        sleep_cpu();
    }
}

ISR(TIMER4_OVF_vect, ISR_BLOCK) {
    static uint8_t s = 1;
    if (s) {
        s = 0;
        TCNT4 = 64736;
    } else {
        s = 1;
        TCNT4 = 65136;
    }
    PORTH ^= 1 << 3;
}

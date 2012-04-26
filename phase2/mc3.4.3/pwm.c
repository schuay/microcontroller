#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/cpufunc.h>

void setup(void) {
    DDRH = 0xff;
    PORTH = 0x00;

    /* no prescaler, Fast PWM with ICR4 as TOP
     * Set OCnA on compare match */
    TCCR4A |= _BV(WGM41) | _BV(COM4A1) | _BV(COM4A0);
    TCCR4B |= _BV(CS40) | _BV(WGM42) | _BV(WGM43);

    // 1/16000000 * mult * prescaler = time
    // mult = time * fcpu /  prescaler 
    // mult = 25 us * 16000000 = 400
    //
    // overflow at 2^16
    // TCNT4 = 2^16 - mult = 65136
    //
    ICR4 = 400 + 800;
    OCR4A = 400;
}

int main(void) {
    setup();
    sleep_enable();
    sei();

    for (;;) {
        sleep_cpu();
    }
}

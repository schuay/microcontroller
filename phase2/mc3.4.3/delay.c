#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/cpufunc.h>
#include <util/delay.h>

void setup(void) {
    DDRH = 0xff;
    PORTH = 0x00;
}

int main(void) {
    setup();

    for (;;) {
        // Note: compiler optimizations and F_CPU must be present
        _delay_us(25);

        PORTH = 1 << 3;

        _delay_us(50);

        PORTH = 0x00;
    }
}


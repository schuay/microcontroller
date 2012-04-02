#include <avr/io.h>

volatile uint16_t erg;

void fcalc(void) {
    float fA = 0.8;
    float fB = 0.5;
    erg = (uint16_t)(10*fA + fB);
}

void icalc(void) {
    uint16_t A = 8;
    uint16_t B = 5;
    erg = (10*A + B)/10;
}

int main(void) {
    DDRB = 0xff;
    PORTB = 0x00;

    DDRA = 0x00;
    PORTA = 0xff;

    PORTB =  1 << PB0;

    if (PINA & (1 << PA0)) {
        fcalc();
    } else {
        icalc();
    }

    PORTB = 0x00;

    for (;;) ;
}

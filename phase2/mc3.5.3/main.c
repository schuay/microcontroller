#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "lcd.h"
#include "uart_streams.h"

/* TIMER4: 5 ms */
#define TIMER4_VAL (10000)
#define TIMER4_PRESCALER (8)

/* UART and LCD output don't work correctly with several prescalers
 * for some reason. Just output the value to PORTA/PORTC. */

void setup(void) {
    DDRA = 0xff;
    DDRC = 0xff;
    DDRB = 0x00;
    PORTB = 0xff;

/*    TCCR4B |= _BV(WGM42) | _BV(CS41);
    OCR4A = 10000;
    TIMSK4 |= _BV(OCIE4A); */

    ADCSRA |= _BV(ADEN) | _BV(ADIE) | _BV(ADPS2);
//    ADCSRA = (ADCSRA & __extension__ 0b11111000) | (PINB & __extension__ 0b00000111);

//    uart_streams_init();
//    initLcd();

    set_sleep_mode(SLEEP_MODE_ADC);
    sleep_enable();
    sei();
}

int main(void) {
    setup();

    for (;;) {
        sleep_cpu();
    }
}

ISR(ADC_vect, ISR_BLOCK) {
    uint16_t adc = ADC;
    PORTA = (uint8_t)(adc >> 8);
    PORTC = (uint8_t)adc;
    ADCSRA = (ADCSRA & __extension__ 0b10111000) | (PINB & __extension__ 0b00000111);
}

ISR(TIMER4_COMPA_vect, ISR_BLOCK) {
    syncScreen();
}

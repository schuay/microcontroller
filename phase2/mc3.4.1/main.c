#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>

uint8_t ovf = 0;
uint16_t last = 0;

#define TICKS_PER_100_MS (16000000 / (10 * 1024))

int main(void) {
    DDRA = 0xff;

    DDRD |= _BV(DDD4);
    PORTD |= _BV(PD4);

    DDRD &= ~_BV(DDD0);
    PORTD |= _BV(PD0);

    TCCR1B = _BV(CS12) | _BV(CS10); // 1024 prescaler
    TIMSK1 |= _BV(ICIE1) | _BV(TOIE1); // enable interrupts: input capture, overflow

    EICRA |= _BV(ISC01);
    EIMSK |= _BV(INT0);

    sleep_enable();
    sei();

    for (;;) {
        sleep_cpu();
    }
}

void display_time(uint16_t ticks, uint8_t overflows) {
    /* This isn't perfect, but the input capture works. */
    uint16_t ms100 = ticks / TICKS_PER_100_MS + overflows * 0xFFFF / TICKS_PER_100_MS;
    if (ms100 / 100) {
        PORTA = 0xff;
        return;
    }
    ms100 = ms100 % 100;
    uint8_t porta = (ms100 / 10) | ((ms100 % 10) << 4);
    PORTA = porta;
}

ISR(INT0_vect, ISR_BLOCK) {
    PORTD &= ~_BV(PD4);
    PORTD |= _BV(PD4);
}

ISR(TIMER1_CAPT_vect, ISR_BLOCK) {
    uint16_t ticks = ICR1;
    display_time(ticks - last, ovf);
    last = ticks;
    ovf = 0;
}

ISR(TIMER1_OVF_vect, ISR_BLOCK) {
    ovf++;
}

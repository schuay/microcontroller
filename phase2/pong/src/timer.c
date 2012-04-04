#include <avr/io.h>
#include <avr/interrupt.h>

#include "timer.h"
#include "common.h"

#include "uart_streams.h"
#include <assert.h>

#define PRESCALER (1024L)
#define PRESCALER_FLAGS (_BV(CS12) | _BV(CS10))
#define MS_PER_SEC (1000L)

static intr_handler_t ocie0a_handler;

bool timer_set(const struct timer_conf *conf) {
    assert(conf != NULL);

    /* For now, only worry about timer1. */
    assert(conf->timer == 1);

    ocie0a_handler = conf->output_cmp_handler;
    if (ocie0a_handler != NULL) {
        TIMSK1 |= _BV(OCIE1A);
    }

    /* Prescaler, CTC mode */
    TCCR1B = PRESCALER_FLAGS | _BV(WGM12);

    uint32_t cmp = (F_CPU / (PRESCALER * MS_PER_SEC)) * conf->ms;
    assert(cmp > 0 && cmp <= 0xFFFF);
    OCR1A = (uint16_t)cmp;

    return true;
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    ocie0a_handler();
}

#include <avr/io.h>
#include <avr/interrupt.h>

#include "timer.h"
#include "common.h"

#include "uart_streams.h"
#include <assert.h>

#define PRESCALER (1024L)
#define PRESCALER_FLAGS (_BV(CS12) | _BV(CS10))
#define MS_PER_SEC (1000L)

static intr_handler_t ocie1a_handler;
static intr_handler_t ocie3a_handler;
static bool timer1_once;
static bool timer3_once;

bool timer1_set(const struct timer_conf *conf) {
    assert(conf != NULL);

    timer1_once = conf->once;
    ocie1a_handler = conf->output_cmp_handler;
    if (ocie1a_handler != NULL) {
        set_bit(TIMSK1, OCIE1A);
    }

    /* Prescaler, CTC mode */
    TCCR1B = PRESCALER_FLAGS | _BV(WGM12);

    uint32_t cmp = (F_CPU / (PRESCALER * MS_PER_SEC)) * conf->ms;
    assert(cmp > 0 && cmp <= 0xFFFF);
    OCR1A = (uint16_t)cmp;

    return true;
}

bool timer3_set(const struct timer_conf *conf) {
    assert(conf != NULL);

    timer3_once = conf->once;
    ocie3a_handler = conf->output_cmp_handler;
    if (ocie3a_handler != NULL) {
        set_bit(TIMSK3, OCIE1A);
    }

    /* Prescaler, CTC mode */
    TCCR3B = PRESCALER_FLAGS | _BV(WGM32);

    uint32_t cmp = (F_CPU / (PRESCALER * MS_PER_SEC)) * conf->ms;
    assert(cmp > 0 && cmp <= 0xFFFF);
    OCR3A = (uint16_t)cmp;

    return true;
}

ISR(TIMER3_COMPA_vect, ISR_BLOCK) {
    ocie3a_handler();
    if (timer3_once) {
        clr_bit(TIMSK3, OCIE3A);
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    ocie1a_handler();
    if (timer1_once) {
        clr_bit(TIMSK1, OCIE1A);
    }
}

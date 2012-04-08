#include <avr/io.h>
#include <avr/interrupt.h>

#include "timer.h"
#include "common.h"

#include "uart_streams.h"
#include <assert.h>

#define PRESCALER (1024L)
#define PRESCALER_FLAGS (_BV(CS12) | _BV(CS10))
#define MS_PER_SEC (1000L)

static volatile uint8_t *TCCRnB[] =
    { &TCCR1B, &TCCR3B, &TCCR4B, &TCCR5B };
static volatile uint8_t *TIMSKn[] =
    { &TIMSK1, &TIMSK3, &TIMSK4, &TIMSK5 };
static volatile uint16_t *OCRnA[] =
    { &OCR1A, &OCR3A, &OCR4A, &OCR5A };

static intr_handler_t ocieNa_handler[TimerNEnd];
static bool timerN_once[TimerNEnd];

bool timer_set(const struct timer_conf *conf) {
    assert(conf != NULL);
    assert(conf->timer < Timer0); /* 16 bit timers only for now */

    enum TimerN n = conf->timer;

    timerN_once[n] = conf->once;
    ocieNa_handler[n] = conf->output_cmp_handler;

    /* Enable interrupts. */
    if (conf->output_cmp_handler != NULL) {
        set_bit(*TIMSKn[n], OCIE1A);
    }

    /* Prescaler, CTC mode */
    *TCCRnB[n] = PRESCALER_FLAGS | _BV(WGM12);

    uint32_t cmp = (F_CPU / (PRESCALER * MS_PER_SEC)) * conf->ms;
    assert(cmp > 0 && cmp <= 0xFFFF);
    *OCRnA[n] = (uint16_t)cmp;

    return true;
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
    ocieNa_handler[Timer1]();
    if (timerN_once[Timer1]) {
        clr_bit(*TIMSKn[Timer1], OCIE1A);
    }
}

ISR(TIMER3_COMPA_vect, ISR_BLOCK) {
    ocieNa_handler[Timer3]();
    if (timerN_once[Timer3]) {
        clr_bit(*TIMSKn[Timer3], OCIE1A);
    }
}

ISR(TIMER4_COMPA_vect, ISR_BLOCK) {
    ocieNa_handler[Timer4]();
    if (timerN_once[Timer4]) {
        clr_bit(*TIMSKn[Timer4], OCIE1A);
    }
}

ISR(TIMER5_COMPA_vect, ISR_BLOCK) {
    ocieNa_handler[Timer5]();
    if (timerN_once[Timer5]) {
        clr_bit(*TIMSKn[Timer5], OCIE1A);
    }
}

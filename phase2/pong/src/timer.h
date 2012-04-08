#ifndef TIMER_H
#define TIMER_H

#include <stdbool.h>
#include <stdint.h>
#include "common.h"

enum TimerN {
    Timer1,     /* 16 bit timers */
    Timer3,
    Timer4,
    Timer5,
    Timer0,     /* 8 bit timers, unused for now */
    Timer2,
    TimerNEnd,
};

struct timer_conf {
    enum TimerN timer;
    bool once;
    uint16_t ms;
    intr_handler_t output_cmp_handler;
};

bool timer_set(const struct timer_conf *conf);

#endif /* TIMER_H */

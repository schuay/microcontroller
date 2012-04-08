#ifndef TIMER_H
#define TIMER_H

#include <stdbool.h>
#include <stdint.h>
#include "common.h"

struct timer_conf {
    bool once;
    uint16_t ms;
    intr_handler_t output_cmp_handler;
};

bool timer1_set(const struct timer_conf *conf);
bool timer3_set(const struct timer_conf *conf);

#endif /* TIMER_H */

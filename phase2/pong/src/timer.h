#ifndef TIMER_H
#define TIMER_H

#include <stdbool.h>
#include <stdint.h>
#include "common.h"

struct timer_conf {
    uint8_t timer;
    uint16_t ms;
    intr_handler_t output_cmp_handler;
};

bool timer_set(const struct timer_conf *conf);

#endif /* TIMER_H */

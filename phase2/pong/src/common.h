#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

#define F_CPU 16000000L

typedef void (*intr_handler_t)(void);
typedef void (*recv_handler_t)(uint8_t);

#define set_bit(addr, bit) do { addr |= _BV(bit); } while (0);
#define clr_bit(addr, bit) do { addr &= ~_BV(bit); } while (0);

#endif /* COMMON_H */

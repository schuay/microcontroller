#ifndef COMMON_H
#define COMMON_H

#define F_CPU 16000000L

typedef void (*intr_handler_t)(void);

#define set_bit(addr, bit) do { addr |= _BV(bit); } while (0);
#define clr_bit(addr, bit) do { addr &= ~_BV(bit); } while (0);

#endif /* COMMON_H */

#ifndef RINGBUFFER_H
#define RINGBUFFER_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct __ringbuffer_t ringbuffer_t;

/* If appropriate, calls to ringbuffer methods should be 
 * protected by turning off interrupts. */

ringbuffer_t *ringbuffer_init(size_t size);
bool ringbuffer_put(ringbuffer_t *buf, uint8_t data);
bool ringbuffer_get(ringbuffer_t *buf, uint8_t *result);

#endif /* RINGBUFFER_H */
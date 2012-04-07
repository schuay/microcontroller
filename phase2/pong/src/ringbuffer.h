#ifndef RINGBUFFER_H
#define RINGBUFFER_H

/**
 * @file ringbuffer.h
 *
 * Circular buffer.
 * Methods are *not* synchronized, and need to be protected
 * if needed by turning off interrupts. */

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

/**
 * The ringbuffer.
 */
typedef struct __ringbuffer_t ringbuffer_t;

/**
 * Creates a ringbuffer with the specified size and returns a
 * pointer to it. */
ringbuffer_t *ringbuffer_init(size_t size);

/**
 * Attempts to put data into the specified buffer.
 * @return Returns true if successful, false if the buffer
 *         is full.
 */
bool ringbuffer_put(ringbuffer_t *buf, uint8_t data);

/**
 * Attempts to fetch data from the specified buffer into
 * result.
 * @return Returns true if successful, false if the buffer
 *         is empty.
 */
bool ringbuffer_get(ringbuffer_t *buf, uint8_t *result);

#endif /* RINGBUFFER_H */

#include <string.h>
#include <stdlib.h>

#include "uart_streams.h"
#include <assert.h>

#include "ringbuffer.h"

struct __ringbuffer_t {
    uint8_t *data;
    uint8_t *write;
    uint8_t *read;
    bool full;
    bool empty;
    size_t size;
};

ringbuffer_t *ringbuffer_init(size_t size) {
    assert(size > 0);

    ringbuffer_t *buf = malloc(sizeof(ringbuffer_t));
    assert(buf != NULL);

    buf->size = size;
    buf->data = malloc(sizeof(uint8_t) * size);
    assert(buf->data != NULL);

    buf->write = buf->read = buf->data;
    buf->full = false;
    buf->empty = true;

    return buf;
}

bool ringbuffer_put(ringbuffer_t *buf, uint8_t data) {
    assert(buf != NULL);

    if (buf->full) {
        return false;
    }
    *(buf->write++) = data;

    /* Wrap write pointer to beginning if we've reached the end. */
    if (buf->write == buf->data + buf->size) {
        buf->write = buf->data;
    }

    buf->empty = false;
    if (buf->write == buf->read) {
        buf->full = true;
    }

    return true;
}
bool ringbuffer_get(ringbuffer_t *buf, uint8_t *result) {
    assert(buf != NULL);
    assert(result != NULL);

    if (buf->empty) {
        return false;
    }
    *result = *(buf->read++);

    /* Wrap read pointer to beginning if we've reached the end. */
    if (buf->read == buf->data + buf->size) {
        buf->read = buf->data;
    }

    buf->full = false;
    if (buf->write == buf->read) {
        buf->empty = true;
    }

    return true;
}

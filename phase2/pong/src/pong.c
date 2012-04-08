#include "uart_streams.h"
#include <assert.h>
#include <stdio.h>

#include "pong.h"

struct pong_state_t {
    /* Field */
    uint8_t width, height;  /* Board dimensions, including: */
    uint8_t frame_height;   /*  the height of the frame at the top and bottom, and */
    uint8_t horizontal_pad; /*  the area behind the paddle. */

    /* Paddles */
    uint8_t lpady, rpady;

    /* Ball */
    uint8_t x, y;
    int8_t dx, dy;
};

static struct pong_state_t state;

void pong_print(void) {
    printf("x: %d y: %d\n", state.x, state.y);
}

void pong_init(void) {
    state.width = 128;
    state.height = 64;
    state.frame_height = 1;
    state.horizontal_pad = 10;

    state.lpady = state.rpady = (state.height - 2 * state.frame_height) / 2;

    /* x, y, dx, dy TODO */
    state.x = state.y = 1;
    state.dx = state.dy = 5;
}

void pong_ball_step(void) {
    assert(state.x < state.width);
    assert(state.y < state.height);

    int16_t nextx = state.x + state.dx;
    int16_t nexty = state.y + state.dy;

    if (nexty <= 0 + state.frame_height) {
        state.dy = - state.dy;
        nexty = state.frame_height - nexty;
    } else if (nexty >= state.height - state.frame_height - 1) {
        state.dy = - state.dy;
        nexty = 2 * (state.height - state.frame_height - 1) - nexty;
    }

    if (nextx <= 0) {
        state.dx = - state.dx;
        nextx = - nextx;
    } else if (nextx >= state.width - 1) {
        state.dx = - state.dx;
        nextx = 2 * (state.width - 1) - nextx;
    }

    state.x = nextx;
    state.y = nexty;
}

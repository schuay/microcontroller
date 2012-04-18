#include "uart_streams.h"
#include <assert.h>
#include <stdio.h>

#include "glcd.h"
#include "glcd_hal.h"
#include "pong.h"

#define PADDLE_HEIGHT (10)

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

void pong_move(uint8_t player, enum direction dir __attribute ((unused))) {
    assert(player < 2);
    uint8_t *pady = NULL;

    switch (player) {
    case 0:
        pady = &state.lpady;
        break;
    case 1:
        pady = &state.rpady;
        break;
    default:
        assert(0);
    }

    switch (dir) {
    case Up:
        if (*pady == 0) {
            break;
        }
        (*pady)--;
        break;
    case Down:
        if (*pady + PADDLE_HEIGHT == HEIGHT - 1) {
            break;
        }
        (*pady)++;
        break;
    default:
        assert(0);
    }
}

void pong_draw(void) {
    /* Clear screen. */
    glcdFillScreen(0x00);

    xy_point padlt = { 0, state.lpady },
             padlb = { 0, state.lpady + PADDLE_HEIGHT },
             padrt = { WIDTH - 1, state.rpady },
             padrb = { WIDTH - 1, state.rpady + PADDLE_HEIGHT };

    /* Draw paddles. */
    glcdDrawLine(padlt, padlb, glcdSetPixel);
    glcdDrawLine(padrt, padrb, glcdSetPixel);

    /* Draw ball. */
    glcdSetPixel(state.x, state.y);
    glcdSetPixel(state.x + 1, state.y);
    glcdSetPixel(state.x, state.y + 1);
    glcdSetPixel(state.x + 1, state.y + 1);
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

static bool _hit_paddle(uint8_t pady, uint8_t y, uint8_t nexty) {
    uint8_t miny = (y < nexty) ? y : nexty;
    uint8_t maxy = (y < nexty) ? nexty : y;

    return (miny <= pady && maxy >= pady)
        || (miny <= pady + PADDLE_HEIGHT && maxy >= pady + PADDLE_HEIGHT)
        || (miny >= pady && maxy <= pady + PADDLE_HEIGHT);
}

bool pong_ball_step(void) {
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
        if (!_hit_paddle(state.lpady, state.y, nexty)) {
            return true;
        }
    } else if (nextx >= state.width - 1) {
        state.dx = - state.dx;
        nextx = 2 * (state.width - 1) - nextx;
        if (!_hit_paddle(state.rpady, state.y, nexty)) {
            return true;
        }
    }

    state.x = nextx;
    state.y = nexty;

    return false;
}

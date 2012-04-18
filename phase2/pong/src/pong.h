#ifndef PONG_H
#define PONG_H

#include <stdbool.h>

enum direction {
    Up,
    Down,
};

void pong_print(void);
void pong_init(void);

/**
 * Performs ball movement.
 * @return Returns true if a player has scored, false otherwise.
 */
bool pong_ball_step(void);

void pong_move(uint8_t player, enum direction dir);
void pong_draw(void);

#endif /* PONG_H */

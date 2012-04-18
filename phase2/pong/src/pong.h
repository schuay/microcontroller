#ifndef PONG_H
#define PONG_H

enum direction {
    Up,
    Down,
};

void pong_print(void);
void pong_init(void);
void pong_ball_step(void);
void pong_move(uint8_t player, enum direction dir);

#endif /* PONG_H */

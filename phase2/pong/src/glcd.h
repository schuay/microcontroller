#ifndef GLCD_H
#define GLCD_H

/**
 * Handles all interaction with the GLCD.
 */

/**
 * Sets the pixel located at coordinates (x, y).
 */
void glcd_set_pixel(uint8_t x, uint8_t y);

/**
 * Draws a line from (x0, y0) to (x1, y1).
 */
void glcd_draw_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1);

/**
 * Draws a 3x3 block centered at (x, y).
 */
void glcd_draw_dot(uint8_t x, uint8_t y);

/**
 * Clears the screen.
 */
void glcd_clr_screen(void);

/**
 * Initializes the GLCD.
 */
void glcd_init(void);

#endif /* GLCD_H */

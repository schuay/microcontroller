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
 * Clears the screen.
 */
void glcd_clr_screen(void);

/**
 * Initializes the GLCD.
 */
void glcd_init(void);

#endif /* GLCD_H */

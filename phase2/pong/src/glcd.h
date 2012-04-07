#ifndef GLCD_H
#define GLCD_H

/**
 * Represents an unsigned 8bit point.
 */
typedef struct xy_point_t
{
    uint8_t x, y;
} xy_point;

/**
 * Handles all interaction with the GLCD.
 */

typedef void (*draw_fn)(const uint8_t, const uint8_t);

/**
 * Draws a line from (x0, y0) to (x1, y1).
 */
void glcd_draw_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1);

/**
 * Draws a 3x3 block centered at (x, y).
 */
void glcd_draw_dot(uint8_t x, uint8_t y);

/**
 * Initializes the GLCD.
 */
void glcdInit(void);

/**
 * Fills the screen with the specified pattern.
 */
void glcdFillScreen(const uint8_t pattern);

/**
 * Sets the pixel located at coordinates (x, y).
 */
void glcdSetPixel(const uint8_t x, const uint8_t y);
void glcdClearPixel(const uint8_t x, const uint8_t y);
void glcdInvertPixel(const uint8_t x, const uint8_t y);

void glcdDrawLine(const xy_point p1, const xy_point p2, draw_fn drawPx);
void glcdDrawRect(const xy_point p1, const xy_point p2, draw_fn drawPx);
/*
void glcdDrawCircle(const xy_point c, const uint8_t radius, draw_fn drawPx);
*/

/* Not implemented
 * void glcdDrawChar(const char c, const xy_point p, const font *f, draw_fn drawPx);
 * void glcdDrawText(const char *text, const xy_point p, const font *f, draw_fn drawPx);
 */

#endif /* GLCD_H */

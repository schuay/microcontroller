#ifndef __GLCD_DRIVER__
#define    __GLCD_DRIVER__

#include <avr/io.h>
#include <font.h>

/* Port configuration */
#define GLCD_CTRL_PORT          (PORTE)
#define GLCD_CTRL_DDR           (DDRE)
#define GLCD_CTRL_RS            (PE4)
#define GLCD_CTRL_RW            (PE5)
#define GLCD_CTRL_E             (PE6)
#define GLCD_CTRL_CS0           (PE2)
#define GLCD_CTRL_CS1           (PE3)
#define GLCD_CTRL_RESET         (PE7)

#define GLCD_DATA_PORT          (PORTA)
#define GLCD_DATA_DDR           (DDRA)
#define GLCD_DATA_PIN           (PINA)

#define GLCD_FILL				0xff
#define GLCD_CLEAR				0x00

/** Number of spaces that tabs (\t) is replaced with. */
#define TAB_WIDTH               (2)

/*  Use this macros if you want sth real equal sided,
    the LCD dots don't have a squared aspect ratio. */

/** Returns the aspect equal height of a given width. */
#define ASPECT_HEIGHT(w)        (((w) * 58) / 42)
/** Returns the aspect equal width of a given height. */
#define ASPECT_WIDTH(h)         (((h) * 42) / 58)

/*  Use this macros if you want faster calculation,
    for non-constants */

/** Returns the aspect equal height of a given width.
    Fast and inprecise version. */
#define ASPECT_HEIGHT_F(w)      (((w) * 11)>>3)
/** Returns the aspect equal width of a given height.
    Fast and inprecise version. */
#define ASPECT_WIDTH_F(h)       (((h) * 3)>>2)

/** \brief      Represents an unsigned 8bit point. */
typedef struct xy_point_t
{
    uint8_t x, y;
} xy_point;

/** \brief      Initializes port and clears the content of the GLCD. */
void    glcdInit(void);

/* drawing functions */

/** \brief      Fills the entire lcd with the pattern fill.
                If you want to clear the screen use fill = GLCD_CLEAR.
                If you want to blacken the screen use fill = GLCD_FILL.

    \param fill Pattern to fill screen with.
*/
void    glcdFillScreen(const uint8_t fill);

/** \brief      Sets one single pixel
    \param x    x-coordinate of pixel to set.
    \param y    y-coordinate of pixel to set.
*/
void    glcdSetPixel(const uint8_t x, const uint8_t y);

/** \brief      Clears one single pixel
    \param x    x-coordinate of pixel to clear.
    \param y    y-coordinate of pixel to clear.
*/
void    glcdClearPixel(const uint8_t x, const uint8_t y);

/** \brief      Inverts one single pixel
    \param x    x-coordinate of pixel to invert.
    \param y    y-coordinate of pixel to invert.
*/
void    glcdInvertPixel(const uint8_t x, const uint8_t y);

/** \brief          Draws a line from p1 to p2 using a given drawing function.
    \param p1       Start point.
    \param p2       End point.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawLine(const xy_point p1, const xy_point p2, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a rectangle from p1 to p2 using a given drawing function.
    \param p1       First corner.
    \param p2       Second corner.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawRect(const xy_point p1, const xy_point p2, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Fills a rectangle from p1 to p2 using a given drawing function.
    \param p1       First corner.
    \param p2       Second corner.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdFillRect(const xy_point p1, const xy_point p2, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a circle with given center and radius using a given drawing function.
    \param c        Center point.
    \param radius   Radius.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawCircle(const xy_point c, const uint8_t radius, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws an ellipse with given center and two radii using a given drawing function.
    \param c        Center point.
    \param radiusX  First radius of ellipse (x-axis).
    \param radiusY  Second radius of ellipse (y-axis).
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawEllipse(const xy_point c, const uint8_t radiusX, const uint8_t radiusY, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a vertical line at a given x-coordinate using a given drawing function.
    \param x        x-position of the line.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawVertical(const uint8_t x, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a horizontal line at a given y-coordinate using a given drawing function.
    \param y        y-position of the line.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawHorizontal(const uint8_t y, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a character a given point using a given drawing function and a given font.
    \param c        Character to display.
    \param p        Position where to display the character (the anchor is bottom left).
    \param f        Font to use.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawChar(const char c, const xy_point p, const font* f, void (*drawPx)(const uint8_t, const uint8_t));

/** \brief          Draws a character a given point using a given drawing function and a given font.
    \param text     Text to display.
    \param p        Position where to display the text (the anchor is bottom left).
    \param f        Font to use.
    \param drawPx   Drawing function. Should be setPixelGLCD, clearPixelGLCD or invertPixelGLCD.
*/
void    glcdDrawText(const char *text, const xy_point p, const font* f, void (*drawPx)(const uint8_t, const uint8_t));

#endif


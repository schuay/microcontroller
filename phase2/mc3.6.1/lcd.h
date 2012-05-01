/**
 * This is a simple LCD driver for the text LCD on
 * the MikroElektronika BigAVR6 board.
 * It uses the 4bit parallel control and
 * only provides functions for displaying
 * strings, 8 bit unsigned and characters.
 * Use printf-methods for more power.
 * Custom characters are not supported.
 */

#ifndef __LCD_DRIVER__
#define	__LCD_DRIVER__

#include <avr/io.h>
#include <stdio.h>

/* Port */
#define DATA_DDR        (DDRC)
#define DATA_PORT       (PORTC)
#define DATA_PIN        (PINC)
/* Pins */
#define DATA_RS         (PC2)
#define DATA_EN         (PC3)
#define DATA_D4         (PC4)
#define DATA_D5         (PC5)
#define DATA_D6         (PC6)
#define DATA_D7         (PC7)

#define LCD_WIDTH       (16)
#define LCD_HEIGHT      (2)
#define LCD_NUM_CHARS   (LCD_WIDTH * LCD_HEIGHT)

/** \brief  File for printing to the screen using fprintf.
            Use \r to start at position (0/0) and
                \n to get to the next line. */
extern FILE *lcdout;

/** \brief  Initializes the port for controlling the LCD and
            clears the framebuffer. */
extern void initLcd(void);

/** \brief  Syncronizes the screen. Sends exactly one command
            per call, so call it periodically in a timer ISR. */
extern void syncScreen(void);

/** \brief  Clears the framebuffer. */
extern void clearScreen(void);

/** \brief  Writes a string to the framebuffer.
            x should be in [0, LCD_WIDTH) and y in [0, LCD_HEIGHT).
    \param  str     String to display, must be zero-terminated.
    \param  x       x position where the string should be displayed.
    \param  y       y position where the string should be displayed.
*/
extern void dispString(const char *str, uint8_t x, const uint8_t y);

/** \brief  Writes a unsigned 8 bit integer to the framebuffer at position (x/y).
            x should be in [0, LCD_WIDTH) and y in [0, LCD_HEIGHT).
    \param  num     Number to display.
    \param  x       x position where the number should be displayed,
                    be aware, it is right aligned!
    \param  y       y position where the number should be displayed.
*/
extern void dispUint8(uint8_t num, uint8_t x, const uint8_t y);

/** \brief  Writes one character to the framebuffer at position (x/y).
            x should be in [0, LCD_WIDTH) and y in [0, LCD_HEIGHT).
    \param  c       Character to display.
    \param  x       x position where the character should be displayed.
    \param  y       y position where the character should be displayed.
*/
extern void dispChar(const char c, const uint8_t x, const uint8_t y);

#endif

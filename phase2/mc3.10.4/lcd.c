#include "lcd.h"

#include <avr/io.h>

#define F_CPU (16000000UL)
#include <util/delay.h>

#define EXT __extension__
#define set_bit(reg, bit) do { reg |= _BV(bit); } while (0);
#define clr_bit(reg, bit) do { reg &= ~_BV(bit); } while (0);

enum LCDPins {
    RS = PC2,   /* Register Selector. 0: instr write, 1: data write */
    E = PC3,    /* Chip Enable. */
    DB4 = PC4,  /* Data Bus 4. */
    DB5 = PC5,
    DB6 = PC6,
    DB7 = PC7,
};

enum LCDInstructions {
    ClearDisplay = 1 << 0,
    ReturnHome = 1 << 1,
    EntryModeSet = 1 << 2,
    DisplayControl = 1 << 3,
    CursorDisplayShift = 1 << 4,
    FunctionSet = 1 << 5,
    SetCGRAMAddr = 1 << 6,
    SetDDRAMAddr = 1 << 7,
};

enum direction {
    Left = EXT 0b00001000,
    Right = EXT 0b00001100,
};

/** The width of the LCD in characters. */
#define COLS (16)

/** The height of the LCD in characters. */
#define ROWS (2)

static void send_ctl(uint8_t cmd);
static void send_data(uint8_t data);
static void send_byte(uint8_t packet);
static void send_nibble(uint8_t nibble);
static void lcd_clear(void);

static int lcd_putc(char c, FILE *stream);

static FILE _lcdout = FDEV_SETUP_STREAM(lcd_putc, NULL, _FDEV_SETUP_WRITE);
FILE *lcdout = &_lcdout;

#define LEN (37)
static char buffer[LEN];
static uint8_t next_write = 0;
static uint8_t next_read = 0;

static enum direction dir = Left;
static uint8_t shift_off = 0;

void lcd_shift(void)
{
    /* This is limited as it only uses the hardware shift feature,
     * which only handles a buffer 37 chars wide. */
    if (next_read <= COLS) {
        return;
    }

    send_ctl(CursorDisplayShift | dir);

    switch (dir) {
    case Left:
        shift_off++;
        if (shift_off > next_read - COLS) {
            dir = Right;
        }
        break;
    case Right:
        shift_off--;
        if (shift_off == 0) {
            dir = Left;
        }
        break;
    }
}

static int lcd_putc(char c, FILE *stream __attribute__ ((unused)))
{
    if (next_write == LEN) {
        return;
    }
    buffer[next_write] = c;
    next_write = (next_write + 1) % 255;

    return 0;
}

static void lcd_clear(void) {
    send_ctl(ClearDisplay);
    _delay_us(1530);
}

void lcd_sync(void)
{
    if (next_read == 255 || next_read == next_write) {
        return;
    }

    const uint8_t row = 0;
    const uint8_t col = next_read;

    send_ctl(SetDDRAMAddr | (row << 6) | col);
    send_data(buffer[next_read]);

    next_read++;
}

void lcd_init(void) {
    const uint8_t msk = _BV(PC1) | _BV(PC0);

    /* Set PC[2-7] to output and zero it. */
    PORTC &= msk;
    DDRC |= ~msk;

    /* Datasheet: 40ms, Tutor: 50ms. */
    _delay_ms(50);

    /* 8 bit data length.
     * Needs to be sent 3 times to account for all possible states
     * of the LCD. */
    send_nibble(FunctionSet | EXT 0b00010000);
    _delay_us(39);

    send_nibble(FunctionSet | EXT 0b00010000);
    _delay_us(39);

    send_nibble(FunctionSet | EXT 0b00010000);
    _delay_us(39);

    /* Make sure the next send is received correctly in 4 bit mode. */
    send_nibble(FunctionSet);
    _delay_us(39);

    /* 4 bit data length, 2 display lines, 5x11 font type. */
    send_ctl(FunctionSet | EXT 0b00001100);

    _delay_us(39);

    send_ctl(FunctionSet | EXT 0b00001100);

    _delay_us(37);

    /* Enable display. */
    send_ctl(DisplayControl | EXT 0b00000100);

    _delay_us(37);

    lcd_clear();

    /* Entry mode set, shift cursor/DDRAM right.  */
    send_ctl(EntryModeSet | EXT 0b00000010);
}

/**
 * Sends data to the LCD's display RAM.
 */
static void send_data(uint8_t data) {
    set_bit(PORTC, RS);
    send_byte(data);
}

/**
 * Sends cmd to the LCD.
 */
static void send_ctl(uint8_t cmd) {
    clr_bit(PORTC, RS);
    send_byte(cmd);
}

/**
 * Sends upper nibble.
 */
static void send_nibble(uint8_t nibble) {
    const uint8_t msk = 0x0F;

    /* It looks like the only time constraint we need to
     * worry about is the enable cycle time of 1200 ns.
     * However, the disassembly shows 21 cycles between the start
     * of send_nibble to the next call of send_nibble, which
     * takes approximately 1312.5 ns so we should be good. */

    set_bit(PORTC, E);
    PORTC = (PORTC & msk) | (nibble & ~msk);

    /* Short delay (again, this isn't documented but seems to be necessary). */
    _delay_us(1);

    clr_bit(PORTC, E);

    /* Contrary to the datasheet (?) and the comment above,
     * the lcd doesn't work without this delay. I'm not sure
     * why, especially because its over 50 times as much as
     * specified. */
    _delay_us(50);
}

/**
 * Sends first the lower, then the upper nibble.
 */
static void send_byte(uint8_t packet) {
    send_nibble(packet);
    send_nibble(packet << 4);
}

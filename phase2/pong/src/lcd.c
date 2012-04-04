#include <avr/io.h>

#include "common.h"
#include <util/delay.h>

#include "lcd.h"

#include "uart_streams.h"
#include <assert.h>

#define EXT __extension__

/* The LCD is driven by PORTJ.
 * R/W is connected to GND (meaning 'write').
 * D[0-3] are connected to GND.
 *
 * Character DDRAM addresses:
 * 00 01 02 ... 0F
 * 40 41 42 ... 4F
 *
 * Pin mappings are as follows: */
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

static void send_ctl(uint8_t cmd);
static void send_data(uint8_t data);
static void send_byte(uint8_t packet);
static void send_nibble(uint8_t nibble);

void lcd_putchar(char c, uint8_t row, uint8_t col) {
    assert(row < 2);
    assert(col < 16);

    send_ctl(SetDDRAMAddr | (row << 6) | col);
    send_data(c);
}

void lcd_clear(void) {
    send_ctl(ClearDisplay);
}

/* TODO: review timing. */

void lcd_init(void) {
    const uint8_t msk = _BV(PC1) | _BV(PC0);

    /* Set PC[2-7] to output and zero it. */
    PORTC &= msk;
    DDRC |= ~msk;

    _delay_ms(40);

    /* 8 bit data length. */
    send_nibble(FunctionSet | EXT 0b00010000);

    _delay_ms(40);

    /* 4 bit data length, 2 display lines, 5x11 font type. */
    send_ctl(FunctionSet | EXT 0b00001100);

    _delay_ms(40);

    send_ctl(FunctionSet | EXT 0b00001100);

    _delay_ms(38);

    /* Enable display. */
    send_ctl(DisplayControl | EXT 0b00000100);

    _delay_ms(38);

    lcd_clear();

    _delay_ms(38);

    /* Entry mode set, shift cursor/DDRAM right.  */
    send_ctl(EntryModeSet | EXT 0b00000010);

    _delay_ms(2);
}

static void send_data(uint8_t data) {
    PORTC |= _BV(RS);
    send_byte(data);
}

static void send_ctl(uint8_t cmd) {
    PORTC &= ~_BV(RS);
    send_byte(cmd);
}

/* Sends upper nibble. */
static void send_nibble(uint8_t nibble) {
    const uint8_t msk = 0x0F;

    PORTC |= _BV(E);
    PORTC = (PORTC & msk) | (nibble & ~msk);
    PORTC &= ~_BV(E);

    _delay_ms(2);
}

static void send_byte(uint8_t packet) {
    send_nibble(packet);
    send_nibble(packet << 4);
}

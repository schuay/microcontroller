#include <avr/io.h>
#include <avr/sfr_defs.h>

#include "common.h"
#include <util/delay.h>

#include "glcd.h"

#include "uart_streams.h"
#include <assert.h>

#define EXT __extension__
#define PORTE_MSK (EXT 0b10000011) /* NOTE: RST is also masked.
                                      It's low active and should never be
                                      touched. */

/* The GLCD is driven by PORTA and PORTE (PE2-7).
 *
 * Pin mappings are as follows: */
enum GLCDPinsE {
    CS0 = PE2,  /* Select Segment 1 - 64. */
    CS1 = PE3,  /* Select Segment 65 - 128. */
    RS = PE4,   /* Register Select. 0: instr, 1: data */
    RW = PE5,   /* Read/Write: 0: write, 1: read */
    E = PE6,    /* Chip Enable. */
    RST = PE7,  /* Reset. */
};

enum GLCDPinsA {
    D0 = PA0,   /* Data Bus. */
    D1,
    D2,
    D3,
    D4,
    D5,
    D6,
    D7,
};

enum GLCDInstructions {
    DisplayOnOff = EXT 0b00111110,
    SetAddress = EXT 0b01000000,
    SetPage = EXT 0b10111000,
    DisplayStartLine = EXT 0b11000000,
};

static void send_ctl(uint8_t chips, uint8_t cmd);
static void send(uint8_t ctl, uint8_t data);
static void send_data(uint8_t chips, uint8_t data);
static void glcd_set_pos(uint8_t x, uint8_t y);

#define WIDTH (128)
#define HEIGHT (64)
#define PX_PER_LINE (8)
#define PX_PER_CHIP (64)

#define PAGE(x, y) (y / PX_PER_LINE)
#define PIXL(x, y) _BV(y % PX_PER_LINE)
#define CHIP(x, y) _BV(CS1 - x / PX_PER_CHIP)
#define ADDR(x, y) (x % PX_PER_CHIP)

void glcd_set_pixel(uint8_t x, uint8_t y) {
    glcd_set_pos(x, y);
    send_data(CHIP(x, y), PIXL(x, y));
}

void glcd_clr_screen(void) {
    for (int y = 0; y < 8; y++) {
        glcd_set_pos(0, y * PX_PER_LINE);
        glcd_set_pos(PX_PER_CHIP, y * PX_PER_LINE);
        for (int x = 0; x < 64; x++) {
            send_data(_BV(CS0), 0x00);
            send_data(_BV(CS1), 0x00);
        }
    }
}

static void glcd_set_pos(uint8_t x, uint8_t y) {
    assert(x < WIDTH);
    assert(y < HEIGHT);
    
    send_ctl(CHIP(x, y), SetPage | PAGE(x, y));
    send_ctl(CHIP(x, y), SetAddress | ADDR(x, y));
}

void glcd_init(void) {
    PORTA = 0x00;
    DDRA = 0xff;

    PORTE &= PORTE_MSK;
    DDRE |= ~PORTE_MSK;

    /* Make sure RST is high. */
    set_bit(PORTE, RST);

    _delay_ms(40);

    send_ctl(_BV(CS0), DisplayOnOff | 0x01);
    send_ctl(_BV(CS1), DisplayOnOff | 0x01);
    send_ctl(_BV(CS0), DisplayStartLine | 0x00);
    send_ctl(_BV(CS1), DisplayStartLine | 0x00);

    glcd_clr_screen();
}

void send_data(uint8_t chips, uint8_t data) {
    send(chips | _BV(RS), data);
}

static void send_ctl(uint8_t chips, uint8_t cmd) {
    send(chips, cmd);
}

static void send(uint8_t ctl, uint8_t data) {
    /* Pull E low. */
    clr_bit(PORTE, E);

    _delay_us(2);
    
    /* Set data. */
    PORTE = (PORTE & PORTE_MSK) | (ctl & ~PORTE_MSK) | _BV(RST);

    _delay_us(2);

    PORTA = data;

    _delay_us(2);

    /* Pull E high. */
    set_bit(PORTE, E);

    _delay_us(2);

    /* Pull E low. */
    clr_bit(PORTE, E);

    _delay_us(2);
}

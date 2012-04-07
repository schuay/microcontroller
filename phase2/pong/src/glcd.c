#include <avr/io.h>
#include <avr/sfr_defs.h>
#include <avr/cpufunc.h>
#include <stdlib.h>
#include <stdbool.h>

#include "common.h"
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

enum StatusFlags {
    Reset = PA4,
    OnOff = PA5,
    Busy = PA7,
};

enum GLCDInstructions {
    DisplayOnOff = EXT 0b00111110,
    SetAddress = EXT 0b01000000,
    SetPage = EXT 0b10111000,
    DisplayStartLine = EXT 0b11000000,
};

static void _glcd_send_ctl(uint8_t chip, uint8_t cmd);
static void _glcd_send(uint8_t ctl, uint8_t data);
static void _glcd_send_data(uint8_t chip, uint8_t data);
static uint8_t _glcd_recv(uint8_t ctl);
static uint8_t _glcd_recv_status(uint8_t chip);
static uint8_t _glcd_recv_data(uint8_t chip);
static void _glcd_busy_wait(uint8_t chip);
static void _glcd_set_pos(uint8_t x, uint8_t y);

#define WIDTH (128)
#define HEIGHT (64)
#define PX_PER_LINE (8)
#define PX_PER_CHIP (64)

#define PAGE(x, y) (y / PX_PER_LINE)
#define PIXL(x, y) _BV(y % PX_PER_LINE)
#define CHIP(x, y) (CS1 - x / PX_PER_CHIP)
#define ADDR(x, y) (x % PX_PER_CHIP)

void glcd_set_pixel(uint8_t x, uint8_t y) {
    _glcd_set_pos(x, y);
    uint8_t px = _glcd_recv_data(CHIP(x, y));
    _glcd_send_data(CHIP(x, y), px | PIXL(x, y));
}

#define SWAP(x, y) do { uint8_t tmp = x; x = y; y = tmp; } while (false);

/**
 * Bresenham's line algorithm, see
 * http://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
 */
void glcd_draw_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1) {
    const bool steep = abs(y1 - y0) > abs(x1 - x0);
    if (steep) {
        SWAP(x0, y0);
        SWAP(x1, y1);
    }
    if (x0 > x1) {
        SWAP(x0, x1);
        SWAP(y0, y1);
    }

    const uint8_t deltax = x1 - x0;
    const uint8_t deltay = y1 - y0;
    int16_t error = deltax >> 1;
    const int8_t ystep = (y0 < y1 ? 1 : -1);
    int8_t y = y0;

    for (uint8_t x = x0; x <= x1; x++) {
        if (steep) {
            glcd_set_pixel(y, x);
        } else {
            glcd_set_pixel(x, y);
        }
        error -= deltay;
        if (error < 0) {
            y += ystep;
            error += deltax;
        }
    }
}

void glcd_clr_screen(void) {
    for (int y = 0; y < 8; y++) {
        _glcd_set_pos(0, y * PX_PER_LINE);
        _glcd_set_pos(PX_PER_CHIP, y * PX_PER_LINE);
        for (int x = 0; x < 64; x++) {
            _glcd_send_data(CS0, 0x00);
            _glcd_send_data(CS1, 0x00);
        }
    }
}

static void _glcd_set_pos(uint8_t x, uint8_t y) {
    assert(x < WIDTH);
    assert(y < HEIGHT);
    
    _glcd_send_ctl(CHIP(x, y), SetPage | PAGE(x, y));
    _glcd_send_ctl(CHIP(x, y), SetAddress | ADDR(x, y));
}

void glcd_init(void) {
    /* Setup PORTE. Note the special handling of RST.
     * For convenience, PORTE_MSK pretends that RST doesn't
     * belong to the GLCD (we should never touch it).
     * However, we need to set it up as output and pull it high. */
    PORTE = (PORTE & PORTE_MSK) | _BV(RST);
    DDRE |= ~PORTE_MSK | _BV(RST);

    _glcd_send_ctl(CS0, DisplayOnOff | 0x01);
    _glcd_send_ctl(CS1, DisplayOnOff | 0x01);
    _glcd_send_ctl(CS0, DisplayStartLine | 0x00);
    _glcd_send_ctl(CS1, DisplayStartLine | 0x00);

    glcd_clr_screen();
}

/**
 * Writes data into the GLCD display RAM.
 * chip is either CS0 or CS1.
 */
void _glcd_send_data(uint8_t chip, uint8_t data) {
    _glcd_busy_wait(chip);
    _glcd_send(_BV(chip) | _BV(RS), data);
}

/**
 * Sends an instruction to the GLCD.
 * @param chip is either CS0 or CS1.
 * @param cmd is the command to send and will be written to PORTA.
 */
static void _glcd_send_ctl(uint8_t chip, uint8_t cmd) {
    _glcd_busy_wait(chip);
    _glcd_send(_BV(chip), cmd);
}

/**
 * The exact timing is achieved by disassembling the optimized object
 * file and inserting NOPs as needed:
 *
 * \code
    00000000 <_glcd_send>:
       0:   76 98           cbi     0x0e, 6 ; 14
       2:   9f ef           ldi     r25, 0xFF       ; 255
       4:   91 b9           out     0x01, r25       ; 1
       6:   2e b1           in      r18, 0x0e       ; 14
       8:   23 78           andi    r18, 0x83       ; 131
       a:   20 68           ori     r18, 0x80       ; 128
       c:   8c 77           andi    r24, 0x7C       ; 124
       e:   28 2b           or      r18, r24
      10:   2e b9           out     0x0e, r18       ; 14
      12:   62 b9           out     0x02, r22       ; 2
      14:   76 9a           sbi     0x0e, 6 ; 14
      16:   76 98           cbi     0x0e, 6 ; 14
      18:   08 95           ret
 * \endcode
 *
 * cpi, sbi: 2 cycles
 * in, out, andi, ori, or: 1 cycle
 * At 16 MHz, one cycle takes approximately 62.5 ns.
 */
static void _glcd_send(uint8_t ctl, uint8_t data) {
    /* Pull E low. 420 ns */
    clr_bit(PORTE, E);

    /* Set PORTA to output. */
    DDRA = 0xff;

    /* Set data. 140 ns */
    PORTE = (PORTE & PORTE_MSK) | (ctl & ~PORTE_MSK);
    PORTA = data;

    /* Pull E high. 420 ns */
    set_bit(PORTE, E);

    _NOP(); _NOP(); _NOP();
    _NOP(); _NOP(); _NOP();

    /* Pull E low. */
    clr_bit(PORTE, E);
}

static void _glcd_busy_wait(uint8_t chip) {
    uint8_t status;
    do {
       status = _glcd_recv_status(chip);
    } while (status & (_BV(Reset) | _BV(Busy)));
}

/**
 * Reads status from selected chip.
 */
static uint8_t _glcd_recv_status(uint8_t chip) {
    return _glcd_recv(_BV(chip) | _BV(RW));
}

/**
 * Reads display RAM contents at current address
 * from selected chip.
 */
static uint8_t _glcd_recv_data(uint8_t chip) {
    return _glcd_recv(_BV(chip) | _BV(RW) | _BV(RS));
}

/**
 * Sends the ctl instruction to the GLCD and
 * returns read data from PORTA.
 */
static uint8_t _glcd_recv(uint8_t ctl) {
    /* Pull E low. 420 ns */
    clr_bit(PORTE, E);

    /* Set PORTA to input. */
    DDRA = 0x00;

    /* Set data. 140 ns */
    PORTE = (PORTE & PORTE_MSK) | (ctl & ~PORTE_MSK);

    /* Pull E high. 320 ns */
    set_bit(PORTE, E);

    _NOP(); _NOP(); _NOP();
    _NOP(); _NOP();

    /* Read data. */
    uint8_t data = PORTA;

    /* Pull E low. */
    clr_bit(PORTE, E);

    return data;
}

#include <avr/io.h>
#include <avr/sfr_defs.h>
#include <avr/cpufunc.h>

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
#define CHIP(x, y) (CS1 - x / PX_PER_CHIP)
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
            send_data(CS0, 0x00);
            send_data(CS1, 0x00);
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

    /* Setup PORTE. Note the special handling of RST.
     * For convenience, PORTE_MSK pretends that RST doesn't
     * belong to the GLCD (we should never touch it).
     * However, we need to set it up as output and pull it high. */
    PORTE = (PORTE & PORTE_MSK) | _BV(RST);
    DDRE |= ~PORTE_MSK | _BV(RST);

    send_ctl(CS0, DisplayOnOff | 0x01);
    send_ctl(CS1, DisplayOnOff | 0x01);
    send_ctl(CS0, DisplayStartLine | 0x00);
    send_ctl(CS1, DisplayStartLine | 0x00);

    glcd_clr_screen();
}

/**
 * Writes data into the GLCD display RAM.
 * chips is either CS0 or CS1.
 */
void send_data(uint8_t chips, uint8_t data) {
    send(_BV(chips) | _BV(RS), data);
}

/**
 * Sends an instruction to the GLCD.
 * @param chips is either CS0 or CS1.
 * @param cmd is the command to send and will be written to PORTA.
 */
static void send_ctl(uint8_t chips, uint8_t cmd) {
    send(_BV(chips), cmd);
}

/**
 * The exact timing is achieved by disassembling the optimized object
 * file and inserting NOPs as needed:
 *
 * \code
    00000000 <send>:
       0:   76 98           cbi     0x0e, 6 ; 14
       2:   9e b1           in      r25, 0x0e       ; 14
       4:   93 78           andi    r25, 0x83       ; 131
       6:   90 68           ori     r25, 0x80       ; 128
       8:   8c 77           andi    r24, 0x7C       ; 124
       a:   98 2b           or      r25, r24
       c:   9e b9           out     0x0e, r25       ; 14
       e:   62 b9           out     0x02, r22       ; 2
      10:   76 9a           sbi     0x0e, 6 ; 14
      12:   76 98           cbi     0x0e, 6 ; 14
      14:   08 95           ret
 * \endcode
 *
 * cpi, sbi: 2 cycles
 * in, out, andi, ori, or: 1 cycle
 * At 16 MHz, one cycle takes approximately 62.5 ns.
 */
static void send(uint8_t ctl, uint8_t data) {
    /* Pull E low. 420 ns */
    clr_bit(PORTE, E);

    _NOP();

    /* Set data. 140 ns */
    PORTE = (PORTE & PORTE_MSK) | (ctl & ~PORTE_MSK) | _BV(RST);
    PORTA = data;

    /* Pull E high. 420 ns */
    set_bit(PORTE, E);

    _NOP(); _NOP(); _NOP();
    _NOP(); _NOP(); _NOP();

    /* Pull E low. */
    clr_bit(PORTE, E);
}

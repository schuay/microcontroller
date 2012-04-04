#include <avr/io.h>

#include "common.h"
#include <util/delay.h>

#include "glcd.h"

#include "uart_streams.h"
#include <assert.h>

#define EXT __extension__

/* The GLCD is driven by PORTA and PORTE (PE2-7).
 *
 * Pin mappings are as follows: */
enum LCDPins {
    CS1 = PE2,  /* Select Segment 1 - 64. */
    CS2 = PE3,  /* Select Segment 65 - 128. */
    RS = PE4,   /* Register Select. 0: instr, 1: data */
    RW = PE5,   /* Read/Write: 0: write, 1: read */
    E = PE6,    /* Chip Enable. */
    D0 = PA0,   /* Data Bus. */
    D1,
    D2,
    D3,
    D4,
    D5,
    D6,
    D7,
    RST = PE7,  /* Reset. */
};

void glcd_init(void) {
}

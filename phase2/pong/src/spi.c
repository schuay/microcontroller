#include <avr/io.h>

#include "spi.h"

#define PORT_SPI (PORTB)
#define DD_MOSI (DDB2)
#define DD_SCK (DDB1)
#define DDR_SPI (DDRB)

void spi_init(void) {
    /* Clock polarity and clock phase remain at initial values.
     * Clock rate should be set to F_CPU / 4.
     * Half duplex communication.
     */

    /* Set MOSI and SCK output, all others input */
    DDR_SPI = _BV(DD_MOSI) | _BV(DD_SCK);

    /* Enable SPI, Master, set clock rate fck / 4 */
    SPCR = _BV(SPE) | _BV(MSTR);
}

void spiSend(uint8_t data) {
    SPDR = data;
    loop_until_bit_is_set(SPSR, SPIF);
    (void)SPDR;
}

uint8_t spiReceive(void) {
    SPDR = 0x00;
    loop_until_bit_is_set(SPSR, SPIF);
    return SPDR;
}

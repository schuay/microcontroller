#include "spi.h"

void spi_init(void) {
    /* Clock polarity and clock phase remain at initial values.
     * Clock rate should be set to F_CPU / 4.
     * Half duplex communication.
     */
}

void spiSend(uint8_t data) {
    /* Sending starts with the MSB. */
    /* TODO */
    data = data;
}

uint8_t spiReceive(void) {
    /* TODO */
    return 0;
}

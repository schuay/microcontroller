#ifndef SPI_H
#define SPI_H

#include <stdint.h>

void spi_init(void);
void spiSend(uint8_t data);
uint8_t spiReceive(void);

#endif /* SPI_H */

#ifndef SPI_H
#define SPI_H

/**
 * @file spi.h
 *
 * Implementation of low level details handling
 * the communication between the sdcard, the microcontroller,
 * and the mp3 module.
 */

#include <stdint.h>

/**
 * Sets up the board for SPI Master mode.
 */
void spi_init(void);

/**
 * Sends data over SPI.
 */
void spiSend(uint8_t data);

/**
 * Receives byte from SPI.
 */
uint8_t spiReceive(void);

#endif /* SPI_H */

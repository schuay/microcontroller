#ifndef BT_HAL_H
#define BT_HAL_H

/**
 * @file bt_hal.c
 *
 * Low level implementation of communication with the bluetooth
 * board over UART.
 */

#include "util.h"
#include "common.h"

/**
 * Wii button values as received by libwiimote.
 */
enum buttons {
    BtnDown = 1 << 10,
    BtnUp = 1 << 11,
};

/**
 * Sets up all used ports, configures UART3, and resets the bluetooth
 * board.
 *
 * @param sndCallback sndCallback is called by this module when the
 *        UART3 data register is empty, meaning we are ready to transmit
 *        more data.
 * @param rcvCallback rcvCallback is called by this module for each
 *        received byte. Since speed is important, the data is buffered
 *        and then processed with interrupts enabled.
 */
error_t halWT41FcUartInit(intr_handler_t sndCallback, recv_handler_t rcvCallback);

/**
 * Sends byte to the bluetooth module.
 */
error_t halWT41FcUartSend(uint8_t byte);

#endif /* BT_HAL_H */

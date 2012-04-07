#ifndef BT_HAL_H
#define BT_HAL_H

#include "util.h"
#include "common.h"

error_t halWT41FcUartInit(intr_handler_t sndCallback, recv_handler_t rcvCallback);
error_t halWT41FcUartSend(uint8_t byte);

#endif /* BT_HAL_H */

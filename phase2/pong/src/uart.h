#ifndef UART_H
#define UART_H

#include "common.h"

enum ucsrnbflags {
    ReceiverEnable = _BV(RXEN0),
    TransmitterEnable = _BV(TXEN0),
    DataRegEmptyIntrEnable = _BV(UDRIE0),
    TXCompleteIntrEnable = _BV(TXCIE0),
    RXCompleteIntrEnable = _BV(RXCIE0),
};

struct uart_conf {
    uint8_t ucsrnb;
    intr_handler_t data_reg_empty_handler;
};

/* Interrupts must be disabled. */
void uart0_init(const struct uart_conf *conf);

#endif /* UART_H */

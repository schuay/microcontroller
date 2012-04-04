#include <avr/io.h>
#include <avr/interrupt.h>

#include "uart.h"
#include "common.h"

#define BAUD 115200

static intr_handler_t udri0_handler;

void uart0_init(const struct uart_conf *conf) {
    UCSR0B = conf->ucsrnb;

    udri0_handler = conf->data_reg_empty_handler;

#include <util/setbaud.h>
    UBRR0 = UBRR_VALUE;
#if USE_2X
    UCSR0A |= _BV(U2X0);
#else
    UCSR0A &= ~_BV(U2X0);
#endif
}

ISR(USART0_UDRE_vect, ISR_BLOCK) {
    udri0_handler();
}

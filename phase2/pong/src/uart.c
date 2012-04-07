#include <avr/io.h>
#include <avr/interrupt.h>
#include <assert.h>
#include <stdlib.h>

#include "timer.h"
#include "util.h"
#include "uart.h"
#include "common.h"

static intr_handler_t udri0_handler;
static recv_handler_t rxci0_handler;
static intr_handler_t udri3_handler;
static recv_handler_t rxci3_handler;

#define BAUD 1048576 /* 1 MBit */
#define BAUD_TOL 5

void uart3_init(const struct uart_conf *conf) {
    assert(conf != 0);

    udri3_handler = conf->data_reg_empty_handler;
    rxci3_handler = conf->rx_complete_handler;

    UCSR3B = conf->ucsrnb;

#include <util/setbaud.h>
    UBRR3 = UBRR_VALUE;
#if USE_2X
    UCSR3A |= _BV(U2X3);
#else
    UCSR3A &= ~_BV(U2X3);
#endif
}

ISR(USART3_RX_vect, ISR_BLOCK) {
    rxci3_handler(UDR3);
}

ISR(USART3_UDRE_vect, ISR_BLOCK) {
    udri3_handler();
}

#undef BAUD
#undef BAUD_TOL
#define BAUD 115200
#define BAUD_TOL 3

void uart0_init(const struct uart_conf *conf) {
    UCSR0B = conf->ucsrnb;

    udri0_handler = conf->data_reg_empty_handler;
    rxci0_handler = conf->rx_complete_handler;

#include <util/setbaud.h>
    UBRR0 = UBRR_VALUE;
#if USE_2X
    UCSR0A |= _BV(U2X0);
#else
    UCSR0A &= ~_BV(U2X0);
#endif
}

ISR(USART0_RX_vect, ISR_BLOCK) {
    rxci0_handler(UDR3);
}

ISR(USART0_UDRE_vect, ISR_BLOCK) {
    udri0_handler();
}

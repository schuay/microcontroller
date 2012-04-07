#include <avr/io.h>
#include <avr/interrupt.h>
#include <assert.h>
#include <stdlib.h>

#include "util.h"
#include "uart.h"
#include "common.h"

static intr_handler_t udri0_handler;
static intr_handler_t udri3_handler;
static recv_handler_t rxci3_handler;

#define BAUD 1048576 /* 1 MBit */
#define BAUD_TOL 5

error_t uart3_init(intr_handler_t send_callback, recv_handler_t recv_callback) {
    assert(send_callback != 0);
    assert(recv_callback != 0);

    udri3_handler = send_callback;
    rxci3_handler = recv_callback;

    UCSR0B = ReceiverEnable | TransmitterEnable | RXCompleteIntrEnable
             | DataRegEmptyIntrEnable;

#include <util/setbaud.h>
    UBRR3 = UBRR_VALUE;
#if USE_2X
    UCSR3A |= _BV(U2X3);
#else
    UCSR3A &= ~_BV(U2X3);
#endif

    return SUCCESS;
}

error_t halWT41FcUartInit(void (*sndCallback)(void), void (*rcvCallback)(uint8_t)) {
    return uart3_init(sndCallback, rcvCallback);
}

error_t halWT41FcUartSend(uint8_t byte) {
    byte = byte;
    return SUCCESS;
}

#undef BAUD
#undef BAUD_TOL
#define BAUD 115200
#define BAUD_TOL 3

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

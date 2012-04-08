#include <avr/io.h>

#include "uart_streams.h"
#include <assert.h>
#include <stdio.h>

#include "timer.h"
#include "uart.h"
#include "bt_hal.h"
#include "ringbuffer.h"

enum BTPins {
    RTS = PJ2, /* Request to send;
                  Configured as input. Set to HIGH if module cannot
                  handle more data. */
    CTS = PJ3, /* Clear to send;
                  Configured as output. Set to HIGH if we cannot
                  handle more data. */
    RST = PJ5, /* LOW active! */
};

#define RB_SIZE (128)
static ringbuffer_t *_rbuf;

static void _pullPJ5High(void) {
    /* TODO: only enable DataRegEmptyIntr here (and remove it from below).
     */
    set_bit(PORTJ, PJ5);
}

/* TODO: debug. */
static recv_handler_t _recv_callback;
static void _recv_handler(uint8_t data) {
    /* OVERRUN flag uart */
    printf("bt recvd: %x\n", data);
    if (!ringbuffer_put(_rbuf, data)) {
        /* TODO: Set CTS HIGH if < 5 bytes free */
        set_bit(PORTJ, CTS);
    }
    /* TODO: Set CTS LOW if >= RB_SIZE / 2 bytes free. */
    _recv_callback(data);
}

static intr_handler_t _send_callback;
static void _send_handler(void) {
    if (PORTJ & _BV(RTS)) {
        /* Disable DataRegEmptyIntr;
         * Enable pin change intr on RTS;
         * When triggered, reenable DataRegEmptyIntr; */
    }
    _send_callback();
}

error_t halWT41FcUartInit(intr_handler_t sndCallback,
                          recv_handler_t rcvCallback) {
    /* Initialize PORTJ.
     * Configure RTS as input.
     * Configure CTS and RST as output and set both to LOW. */
    PORTJ &= ~(_BV(CTS) | _BV(RST)); 
    DDRJ = (DDRJ | _BV(CTS) | _BV(RST)) & ~_BV(RTS);

    /* Pull P5 low for 5ms to reset bluetooth module. */
    struct timer_conf tc = { Timer3, true, 5, _pullPJ5High };
    timer_set(&tc);

    _rbuf = ringbuffer_init(RB_SIZE);
    assert(_rbuf != NULL);

    _recv_callback = rcvCallback;
    _send_callback = sndCallback;

    /* Init UART3. */
#define BAUD 1000000
#include <util/setbaud.h>
    struct uart_conf uc = {
        Uart3,
        ReceiverEnable | TransmitterEnable | RXCompleteIntrEnable | DataRegEmptyIntrEnable,
        UBRR_VALUE,
#if USE_2X
        true,
#else
        false,
#endif
        _send_handler,
        _recv_handler };
    uart_init(&uc);

    return SUCCESS;
}

error_t halWT41FcUartSend(uint8_t byte) {
    /* Don't call callback until after first send. */
    byte = byte;
    return SUCCESS;
}


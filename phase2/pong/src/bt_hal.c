#include <avr/io.h>
#include <avr/interrupt.h>

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

/** A one byte buffer for sending from
 * the microcontroller to the bluetooth module.
 */
static uint8_t _send_buffer;

/* TODO: debug. */
static recv_handler_t _recv_callback;
static intr_handler_t _send_callback;

static void _recv_handler(uint8_t data) {
    /* Display UART status on PORTH.
     * PH3: data overrun*/
    PORTH = UCSR3A;

    /* For debugging purposes, call this here. */
    _recv_callback(data);

    if (!ringbuffer_put(_rbuf, data)) {
        /* TODO: Set CTS HIGH if < 5 bytes free */
        printf("rbuf full\n");
        set_bit(PORTJ, CTS);
    }

    /* Reenable interrupts after critical work is done. */
    sei();

    printf("bt recvd: %x\n", data);

    /* TODO: Set CTS LOW if >= RB_SIZE / 2 bytes free. */
}

/**
 * Called by UART 3 DataRegEmptyIntr.
 * Performs the actual sending.
 */
static void _send_handler(void) {
    if (PORTJ & _BV(RTS)) {
        printf("RTS ON\n");
        /* Disable DataRegEmptyIntr;
         * Enable pin change intr on RTS;
         * When triggered, reenable DataRegEmptyIntr; */
    }

    printf("bt sending: %x\n", _send_buffer);

    /* Actually send the requested byte.
     * Then, disable the interrupt until there is more data to send.
     */
    UDR3 = _send_buffer;
    UCSR3B &= ~DataRegEmptyIntrEnable;

    /* Let wii module know that we are ready for more data. */
    _send_callback();
}

/**
 * Called by libwii.
 * Lets UART3 know that there is data waiting and sets our internal
 * send buffer.
 */
error_t halWT41FcUartSend(uint8_t byte) {
    _send_buffer = byte;
    UCSR3B |= DataRegEmptyIntrEnable;
    return SUCCESS;
}

static void _bt_continue_init(void) {
    /* Pull RST HIGH. */
    set_bit(PORTJ, RST);

    /* Init UART3. */
#define BAUD 1000000
#include <util/setbaud.h>
    struct uart_conf uc = {
        Uart3,
        ReceiverEnable | TransmitterEnable | RXCompleteIntrEnable,
        UBRR_VALUE,
#if USE_2X
        true,
#else
        false,
#endif
        _send_handler,
        _recv_handler };
    uart_init(&uc);
}

error_t halWT41FcUartInit(intr_handler_t sndCallback,
                          recv_handler_t rcvCallback) {
    /* Use PORTH as debug output. */
    DDRH = 0xff;
    PORTH = 0x00;

    /* Initialize PORTJ.
     * Configure RTS as input.
     * Configure CTS and RST as output and set both to LOW. */
    PORTJ &= ~(_BV(CTS) | _BV(RST)); 
    DDRJ = (DDRJ | _BV(CTS) | _BV(RST)) & ~_BV(RTS);

    /* Pull RST low for 5ms to reset bluetooth module. */
    struct timer_conf tc = { Timer3, true, 5, _bt_continue_init };
    timer_set(&tc);

    _rbuf = ringbuffer_init(RB_SIZE);
    assert(_rbuf != NULL);

    _recv_callback = rcvCallback;
    _send_callback = sndCallback;

    /* The rest of the initialization process takes place once the
     * timer expires. */

    return SUCCESS;
}


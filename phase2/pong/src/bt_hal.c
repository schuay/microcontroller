#include <avr/io.h>
#include <avr/interrupt.h>

#include "uart_streams.h"
#include <assert.h>
#include <stdio.h>

#include "timer.h"
#include "uart.h"
#include "bt_hal.h"

enum BTPins {
    RTS = PJ2, /* Request to send;
                  Configured as input. Set to HIGH if module cannot
                  handle more data. */
    CTS = PJ3, /* Clear to send;
                  Configured as output. Set to HIGH if we cannot
                  handle more data. */
    RST = PJ5, /* LOW active! */
};

/** A one byte buffer for sending from
 * the microcontroller to the bluetooth module.
 */
static uint8_t _send_buffer;

/* TODO: debug. */
static recv_handler_t _recv_callback;
static intr_handler_t _send_callback;

static bool _processing = false;

#define RB_SIZE (128) /* Must be 2^n */
static uint8_t rb_data[RB_SIZE];
static uint8_t rb_read = 0;
static uint8_t rb_write = 0;

/**
 * Returns the number of free slots.
 * This is always the number of actual free slots
 * minus one, because we never want to completely fill the buffer.
 * This lets us efficiently distinguish a full from an empty buffer.
 */
inline static uint8_t rb_free_slots(void) {
    if (rb_write >= rb_read) {
        /* ..r..w.. : 4 free */
        /* b....... : 7 free (b := both) */
        return RB_SIZE - rb_write + rb_read - 1;
    }
    /* ..w..r.. : 2 free */
    return rb_read - rb_write - 1;
}

/**
 * Returns the number of filled slots.
 */
inline static uint8_t rb_data_slots(void) {
    if (rb_write >= rb_read) {
        /* ..r..w.. : 3 data */
        /* b....... : 0 data (b := both) */
        return rb_write - rb_read;
    }
    /* ..w..r.. : 5 data */
    return RB_SIZE - rb_read + rb_write;
}

/**
 * Puts byte into the buffer.
 * The buffer must not be full.
 */
inline static void rb_put(uint8_t byte) {
    rb_data[rb_write++] = byte;
    rb_write &= RB_SIZE - 1;
}

/**
 * Gets byte from the buffer.
 * The buffer must not be empty.
 */
inline static void rb_get(uint8_t *byte) {
    *byte = rb_data[rb_read];
    rb_read = (rb_read + 1) & (RB_SIZE - 1);
}

#define CTS_HIGH (5)
#define CTS_LOW (RB_SIZE / 2)

/**
 * The UART 3 receive complete interrupt handler.
 * For efficiency, implement it in here instead of the default
 * generic handlers in uart.c to avoid losing time.
 */
ISR(USART3_RX_vect, ISR_BLOCK) {
    /* Display UART status on PORTH.
     * PH3: data overrun*/
    PORTH |= UCSR3A;

    if (rb_free_slots() < CTS_HIGH) {
        printf("rbuf full\n");
        set_bit(PORTJ, CTS);
    }

    rb_put(UDR3);

    if (_processing) {
        return;
    }

    _processing = true;

    /* Critical section done, reenable other interrupts.
     * If more speed is needed think about moving this further up still. */
    sei();

    uint8_t byte;

    /* Disable interrupts while accessing ring buffer. */
    cli();
    while (rb_data_slots() != 0) {
        rb_get(&byte);
        sei();
        _recv_callback(byte);
    }

    /* Disable interrupts while setting _processing flag.
     * Don't call sei() because that happens automatically when
     * returning from this. */
    cli();
    _processing = false;

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
        NULL };
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

    _recv_callback = rcvCallback;
    _send_callback = sndCallback;

    /* The rest of the initialization process takes place once the
     * timer expires. */

    return SUCCESS;
}


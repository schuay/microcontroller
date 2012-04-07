#include <avr/io.h>

#include "timer.h"
#include "uart.h"
#include "bt_hal.h"

static void _pullPJ5High(void) {
    set_bit(PORTJ, PJ5);
}

error_t halWT41FcUartInit(intr_handler_t sndCallback, recv_handler_t rcvCallback) {
    /* TODO: How should PORTJ be set up?
     * For now, just init all as output. */

    PORTJ = 0xff;
    DDRJ = 0xff;

    /* Pull P5 low for 5ms to reset bluetooth module. */
    clr_bit(PORTJ, PJ5);
    
    struct timer_conf tc = { 1, 5, _pullPJ5High };
    timer_set(&tc);

    /* Init UART3. */
    struct uart_conf uc = {
        ReceiverEnable | TransmitterEnable
            | RXCompleteIntrEnable | DataRegEmptyIntrEnable,
        sndCallback, rcvCallback };
    uart3_init(&uc);

    return SUCCESS;
}

error_t halWT41FcUartSend(uint8_t byte) {
    byte = byte;
    return SUCCESS;
}


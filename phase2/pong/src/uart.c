#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "ringbuffer.h"

/* The bluetooth module is connected to UART3.
 * 1 Mbit/s asynchronous
 * hardware flow control (RTS/CTS)
 * ringbuffer on receiving end.
 *
 * Of further interest:
 * util/setbaud.h (baud rate calculations for uart)
 *
 */

#define F_CPU 16000000
#define BAUD 9600
#include <util/setbaud.h>

/* Interrupts must be disabled. */
void usart_init(void) {
    /* usart:
     * UCSRnB (usart control and status reg B)
     *      enable receiver, transmitter, and receive interrupt.
     * UBRRn (usart baud rate registers)
     *      init to 9600 bps for 16MHz osc freq.
     *      see table 22-12 on pg.231
     */
    UCSR0B |= (_BV(RXEN0) | _BV(TXEN0) | _BV(RXCIE0));

    /* UBRR_VALUE, USE_2X are set by util/setbaud.h */
    UBRR0 = UBRR_VALUE;
#if USE_2X
    UCSR0A |= _BV(U2X0);
#else
    UCSR0A &= ~_BV(U2X0);
#endif
}

void init(void) {
    usart_init();
    sleep_enable();
    sei();
}

int main(void) {
    init();

    for (;;) {
        sleep_cpu();
    }

    return 0;
}

ISR(USART0_RX_vect, ISR_BLOCK) {
    char in = UDR0;
    UDR0 = PORTA = in;
}

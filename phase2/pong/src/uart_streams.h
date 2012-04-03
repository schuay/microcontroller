#ifndef UART_STREAMS_H
#define UART_STREAMS_H

#include <stdio.h>

/* Sets up stdout to use UART0.
 * Interrupts need to be disabled. */
void uart_streams_init(void);

#endif /* UART_STREAMS_H */

#ifndef STDO_H
#define STDO_H

#include <stdio.h>

// uncomment this for a non-blocking implementation of printf
#define BLOCKING_PRINTF

enum {
	OUTPUT_BUFFER_SIZE = 128,
};

int uart_putchar(char c, FILE *stream);
void printfflush();

#endif


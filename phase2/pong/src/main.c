#include <avr/sleep.h>
#include <avr/pgmspace.h>

#include "uart_streams.h"

int main(void) {
    sleep_enable();
    uart_streams_init();

    printf_P(PSTR("Hello, world!\n"));

    for (;;) {
        sleep_cpu();
    }

    return 0;
}

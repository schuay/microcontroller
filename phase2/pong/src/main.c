#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>

#include "uart_streams.h"
#include "timer.h"
#include "lcd.h"

static volatile uint8_t cntr = 0;

void printmsg(void) {
    printf_P(PSTR("Hello, world! %d\n"), ++cntr);
}

int main(void) {
    sleep_enable();
    uart_streams_init();
    lcd_init();
    sei();

    struct timer_conf conf = { 1, 1000, printmsg };
    timer_set(&conf);
    lcd_putchar('a', 0, 0);
    lcd_putchar('b', 0, 1);
    lcd_putchar('c', 1, 0);
    lcd_putchar('d', 1, 1);
    lcd_putchar('1', 0, 2);

    for (;;) {
        sleep_cpu();
    }

    return 0;
}

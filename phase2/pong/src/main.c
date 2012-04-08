#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>

#include "wii_user.h"

#include "uart_streams.h"
#include "timer.h"
#include "lcd.h"
#include "adc.h"
#include "pong.h"
#include "glcd.h"

enum task_flags {
    RunLogic = 1 << 0,
    ADCWaiting = 1 << 1,
};

struct {
    uint8_t flags;
    uint16_t adc_result;
} glb;

static void tick(void) {
    glb.flags |= RunLogic;
}

static void adc_done(uint16_t result) {
    glb.adc_result = result;
    glb.flags |= ADCWaiting;
}

void rcvButton(uint8_t wii, uint16_t button_states) {
    printf_P(PSTR("Received button %d %d\n"), wii, button_states);
}
void rcvAccel(uint8_t wii, uint16_t x, uint16_t y, uint16_t z) {
    printf_P(PSTR("Received button accel %d %d %d %d\n"), wii, x, y, z);
}

static void init(void) {
    sleep_enable();
    uart_streams_init();
    lcd_init();
    glcdInit();
    pong_init();

    /*
    wiiUserInit(rcvButton, rcvAccel);
    */

    struct adc_conf ac = { adc_done };
    adc_init(&ac);

    struct timer_conf conf = { false, 1000, tick };
    timer1_set(&conf);
}

static void task_logic(void) {
    static int x = 0;
    static int y = 0;
    glcdSetPixel(x, y);
    y += 2;
    if (y >= 64) {
        y = 0;
        x += 2;
    }
}

static void task_adc(void) {
    printf_P(PSTR("ADC Result: %d\n"), glb.adc_result);
}

static void run_tasks(void) {
    printf(".");
    if (glb.flags & RunLogic) {
        glb.flags &= ~RunLogic;
        printf("X\n");
        task_logic();
    }

    if (glb.flags & ADCWaiting) {
        task_adc();
        glb.flags &= ~ADCWaiting;
    }
}

int main(void) {
    init();
    sei();

    printf_P(PSTR("AVR Pong starting up...\n"));

    for (;;) {
        run_tasks();
        sleep_cpu();
    }

    return 0;
}

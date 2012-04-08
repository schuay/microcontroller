#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <string.h>

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

static volatile struct {
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

    wiiUserInit(rcvButton, rcvAccel);

    struct adc_conf ac = { adc_done };
    adc_init(&ac);

    struct timer_conf conf = { Timer1, false, 5, tick };
    timer_set(&conf);

    memset((void *)&glb, 0, sizeof(glb));
}

static void task_logic(void) {
    static int mode = 3;
    static int x = 0;
    static int y = 0;
    static xy_point x0 = { 0, 0 };
    static xy_point x1 = { 5, 5 };

    switch (mode) {
    case 0:
        glcdSetPixel(x, y);
        y += 2;
        if (y >= 64) {
            y -= 64;
            x += 2;
        }
        if (x >= 128) {
            mode++;
            x = 0;
            y = 1;
        }
        break;
    case 1:
        glcdInvertPixel(x, y);
        y += 2;
        if (y >= 64) {
            y -= 64;
            x += 2;
        }
        if (x >= 128) {
            mode++;
            x = y = 0;
        }
        break;
    case 2:
        glcdClearPixel(x, y);
        y += 2;
        if (y >= 64) {
            y -= 64;
            x += 2;
        }
        if (x >= 128) {
            mode++;
            x = y = 1;
            glcdFillScreen(0x00);
        }
        break;
    case 3:
        glcdDrawLine(x0, x1, glcdSetPixel);
        x0.y += 5;
        x1.y += 5;
        if (x1.y >= 64) {
            x1.y = 5;
            x0.y = 0;
            x1.x += 10;
            x0.x += 10;
        }
        if (x1.x >= 128) {
            mode++;
            x = y = 0;
            glcdFillScreen(0x00);
        }
        break;
    default:
        mode = 0;
    }
}

static void task_adc(void) {
    printf_P(PSTR("ADC Result: %d\n"), glb.adc_result);
}

static void run_tasks(void) {
    cli();
    if (glb.flags & RunLogic) {
        glb.flags &= ~RunLogic;
        sei();
        task_logic();
    }

    cli();
    if (glb.flags & ADCWaiting) {
        glb.flags &= ~ADCWaiting;
        sei();
        task_adc();
    }

    sei();
}

int main(void) {
    init();
    sei();

    printf_P(PSTR("AVR Pong starting up...\n"));

    adc_start_conversion();

    for (;;) {
        run_tasks();
        sleep_cpu();
    }

    return 0;
}

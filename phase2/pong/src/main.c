#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>

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

static void init(void) {
    sleep_enable();
    uart_streams_init();
    lcd_init();
    pong_init();

    struct adc_conf ac = { adc_done };
    adc_init(&ac);

    struct timer_conf conf = { 1, 1000, tick };
    timer_set(&conf);
}

static void task_logic(void) {
    static int xy = 0;
    pong_ball_step();
    pong_print();
    glcd_set_pixel(xy, xy);
    xy++;
}

static void task_adc(void) {
    printf_P(PSTR("ADC Result: %d\n"), glb.adc_result);
}

static void run_tasks(void) {
    if (glb.flags & RunLogic) {
        glb.flags &= ~RunLogic;
        task_logic();
    }
    if (glb.flags & ADCWaiting) {
        task_adc();
        glb.flags &= ~ADCWaiting;
    }
}

int main(void) {
    init();
    glcd_init();
    sei();

    for (;;) {
        run_tasks();
        sleep_cpu();
    }

    return 0;
}

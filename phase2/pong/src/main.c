#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <string.h>

#include "uart_streams.h"
#include <assert.h>

#include "timer.h"
#include "lcd.h"
#include "adc.h"
#include "pong.h"
#include "glcd.h"
#include "sdcard.h"
#include "spi.h"
#include "mp3.h"
#include "wii_user.h"
#include "wiimotes.h"
#include "bt_hal.h"

#define WIIMOTE_COUNT (2)

enum task_flags {
    RunLogic = 1 << 0,
    ADCWaiting = 1 << 1,
    MP3DataRequested = 1 << 2,
};

/**
 * The game's state machine.
 *
 * The startup state is GamePaused. In this state, nothing is drawn to the GLCD,
 * game logic is paused, and connections are attempted.
 * If both wiimotes are connected,
 * the state is changed to GameRunning.
 *
 * In GameRunning, game logic is run, and the board is drawn to the LCD.
 * If a wiimote is disconnected, go back to GamePaused.
 * If a point is scored, enter PointScored.
 *
 * In PointScored, an MP3 sound is sent to the MP3 module. No game logic
 * is run, nothing is drawn to the GLCD.
 * Once the MP3 is finished playing, either go back to GameRunning
 * if both wiimotes are still connected,
 * or to GamePaused if a wiimote has disconnected.
 */
enum state {
    GamePaused,
    GameRunning,
    PointScored,
};

static volatile struct {
    uint8_t flags;
    uint8_t ticks;
    uint16_t adc_result;
    uint8_t volume;
    uint16_t buttons[WIIMOTE_COUNT];
    connection_status_t connected[WIIMOTE_COUNT];
    enum state st;
} glb;

static void tick(void) {
    glb.flags |= RunLogic;
    glb.ticks++;
}

static void adc_done(uint16_t result) {
    glb.adc_result = result;
    glb.flags |= ADCWaiting;
}

static void rcvButton(uint8_t wii, uint16_t button_states) {
    printf_P(PSTR("Received button %d %d\n"), wii, button_states);
    glb.buttons[wii] = button_states;
}

static void rcvAccel(uint8_t wii, uint16_t x, uint16_t y, uint16_t z) {
    printf_P(PSTR("Received accel %d %d %d %d\n"), wii, x, y, z);
}

static void mp3_data_req(void) {
    glb.flags |= MP3DataRequested;
}

static void draw_lcd(void) {
    lcd_clear();
    if (glb.connected[0] == CONNECTED) {
        lcd_putstr_P(PSTR("P1"), 0, 0);
    }
    if (glb.connected[1] == CONNECTED) {
        lcd_putstr_P(PSTR("P2"), 0, 14);
    }
    uint8_t p1, p2;
    pong_scores(&p1, &p2);
    lcd_putchar(p1 + '0', 1, 0);
    lcd_putchar(p2 + '0', 1, 15);
}

/**
 * Called when MP3 module requests new data.
 * From observation, it looks like the module requests an entire
 * MP3 at once, and only requests the next one once it is done playing the
 * current file. The next file (if it is short enough) is sent all in one,
 * meaning this function blocks until it's all transferred. */
#define MP3_SD_BEGIN (5821440 / 32)
#define MP3_SD_LEN (45056 / 32)
static void task_mp3(void) {
    assert(glb.st == PointScored);

    static uint32_t ptr = MP3_SD_BEGIN;
    sdcard_block_t buf;
    do {
        if (sdcardReadBlock(ptr++, buf) != SUCCESS) {
            printf_P(PSTR("Error receiving sdcard block\n"));
        }
        mp3SendMusic(buf);
        /* Entire sound has been sent. */
        if (ptr == MP3_SD_BEGIN + MP3_SD_LEN) {
            ptr = MP3_SD_BEGIN;

            cli();
            if (glb.connected[0] == DISCONNECTED
                || glb.connected[1] == DISCONNECTED) {
                glb.st = GamePaused;
            } else {
                glb.st = GameRunning;
            }
            sei();

            draw_lcd();

            break;
        }
    } while (!mp3Busy());
}

static void wii_leds_set(uint8_t wii,
                         error_t status __attribute__ ((unused))) {
    assert(wii < WIIMOTE_COUNT);
}

static void wii_connection_change(uint8_t wii, connection_status_t status) {
    assert(wii < WIIMOTE_COUNT);
    printf_P(PSTR("wii %d connection state change: %d\n"), wii, status);
    glb.connected[wii] = status;
    if (status == CONNECTED) {
        assert(wiiUserSetLeds(wii, _BV(wii), wii_leds_set) == SUCCESS);
    }

    draw_lcd();

    /* If any wiimotes are still disconnected, begin another connection attempt. */
    for (uint8_t i = 0; i < WIIMOTE_COUNT; i++) {
        if (glb.connected[i] == DISCONNECTED) {
            assert(wiiUserConnect(i, wiimotes[i], wii_connection_change) == SUCCESS);
            return;
        }
    }

    /* All wiimotes are connected. */
    glb.st = GameRunning;
}

static void init(void) {
    sleep_enable();
    uart_streams_init();
    lcd_init();
    glcdInit();
    pong_init();
    spi_init();
    sdcardInit();   /* Note: this seems to hang with no board attached. */
    mp3Init(mp3_data_req);
    mp3SetVolume(0);

    error_t ret = wiiUserInit(rcvButton, rcvAccel);
    assert(ret == SUCCESS);
    ret = wiiUserConnect(0, wiimotes[0], wii_connection_change);
    assert(ret == SUCCESS);

    struct adc_conf ac = { adc_done };
    adc_init(&ac);

    struct timer_conf conf = { Timer1, false, 5, tick };
    timer_set(&conf);

    memset((void *)&glb, 0, sizeof(glb));
}

static void __attribute__ ((unused)) test_mode(void) {
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

static void task_logic(void) {
    if (glb.ticks % 20 == 0) {
        if (pong_ball_step()) {
            /* A point has been scored.
             * Display score, reset board, and enter PointScored state. */
            draw_lcd();
            if (pong_game_over()) {
                pong_init();
            } else {
                pong_reset();
            }
            glb.st = PointScored;
            return;
        }
    }
    for (uint8_t i = 0; i < WIIMOTE_COUNT; i++) {
        if (glb.buttons[i] & BtnUp) {
            pong_move(i, Up);
        }
        if (glb.buttons[i] & BtnDown) {
            pong_move(i, Down);
        }
    }
    if (glb.ticks % 5 == 0) {
        pong_draw();
    }
}

#define ADC_UPPER (1023)
#define ADC_SMOOTHING (20)
static void task_adc(void) {
    uint8_t vol = (glb.adc_result >= ADC_UPPER ? 0xFF : glb.adc_result / 4);
    if (abs(vol - glb.volume) > ADC_SMOOTHING) {
        mp3SetVolume(vol);
        glb.volume = vol;
        printf_P(PSTR("Volume: %d\n"), vol);
    }
}

static void run_tasks(void) {
    cli();
    enum state st = glb.st;
    sei();

    switch (st) {
    case GameRunning:
        cli();
        if (glb.flags & RunLogic) {
            glb.flags &= ~RunLogic;
            sei();
            task_logic();
        }
        break;
    case PointScored:
        cli();
        if (glb.flags & MP3DataRequested) {
            sei();
            task_mp3();
        }
        break;
    case GamePaused:
        break;
    default:
        assert(0);
    }

    cli();
    if (glb.ticks % 50 == 0) {
        sei();
        adc_start_conversion();
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
    lcd_putstr_P(PSTR("AVR Pong"), 0, 0);
    lcd_putstr_P(PSTR("Starting up..."), 1, 0);

    for (;;) {
        run_tasks();
        sleep_cpu();
    }

    return 0;
}

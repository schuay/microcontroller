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

/**
 * @file main.c
 *
 * The glue between drivers and game logic.
 * Handles high level tasks such as managing wiimote connections,
 * the game state machine, running the main loop including background tasks, etc.
 */

/** The maximum count of connected wiimotes. */
#define WIIMOTE_COUNT (2)

/** Flags which are used to control task execution during the main loop. */
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

/**
 * This struct stores basically everything that is needed
 * for high level game execution.
 */
static volatile struct {
    uint8_t flags; /**< Controls which tasks are executed during the main
                        loop. */
    uint8_t ticks; /**< Keeps track of how many ticks have passed. Some tasks
                        are only executed once every n ticks. */
    uint16_t adc_result; /**< The result of the latest ADC conversion. */
    uint8_t volume; /**< The current volume. */
    uint16_t buttons[WIIMOTE_COUNT]; /**< The status of wiimote buttons. */
    connection_status_t connected[WIIMOTE_COUNT]; /**< The wiimote connection
                                                       state. */
    enum state st; /**< Current state of our state machine. */
} glb;

/**
 * Our basic 'scheduler'. The main loop is executed (at least)
 * once per tick. The game logic is executed exactly once per tick.
 */
static void tick(void) {
    glb.flags |= RunLogic;
    glb.ticks++;
}

/**
 * Receives and stores ADC conversion results.
 */
static void adc_done(uint16_t result) {
    glb.adc_result = result;
    glb.flags |= ADCWaiting;
}

/**
 * Receives and stores changes to the wii button states.
 */
static void rcvButton(uint8_t wii, uint16_t button_states) {
    debug(PSTR("Received button %d %d\n"), wii, button_states);
    glb.buttons[wii] = button_states;
}

/**
 * Receives and stores changes to the wii accelerometer states.
 */
static void rcvAccel(uint8_t wii __attribute__ ((unused)),
        uint16_t x __attribute__ ((unused)),
        uint16_t y __attribute__ ((unused)),
        uint16_t z __attribute__ ((unused))) {
    debug(PSTR("Received accel %d %d %d %d\n"), wii, x, y, z);
}

/**
 * Called when the MP3 module requests more data.
 */
static void mp3_data_req(void) {
    glb.flags |= MP3DataRequested;
}

/**
 * Draws connected players and current scores to the LCD.
 */
static void draw_lcd(void) {
    lcd_clear();
    if (glb.connected[0] == CONNECTED) {
        lcd_putstr_P(PSTR("P1"), 0, 0);
    }
    if (glb.connected[1] == CONNECTED) {
        lcd_putstr_P(PSTR("P2"), 0, 14);
    }
    if (glb.connected[0] == DISCONNECTED || glb.connected[1] == DISCONNECTED) {
        lcd_putstr_P(PSTR("Connecting"), 0, 3);
    }
    uint8_t p1, p2;
    pong_scores(&p1, &p2);
    lcd_putchar(p1 + '0', 1, 0);
    lcd_putchar(p2 + '0', 1, 15);
}

/**
 * Sends data to the MP3 module as long as it is ready for it,
 * and the MP3 has not been fully transmitted.
 * On completed transfers, switches the state back to GameRunning or
 * GamePaused.
 *
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
            debug(PSTR("Error receiving sdcard block\n"));
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

/**
 * Callback for reporting completion of setting wiimote leds.
 */
static void wii_leds_set(uint8_t wii,
                         error_t status __attribute__ ((unused))) {
    assert(wii < WIIMOTE_COUNT);
}

/**
 * Callback for any changes in wiimote connection state.
 *
 * If a connection has been established, requests setting of appropriate led
 * state.
 * Updates the status shown on the LCD.
 * Manages state according to whether all wiimotes are connected.
 * Starts a new wiimote connection attempt as long as not all wiimotes
 * are connected.
 */
static void wii_connection_change(uint8_t wii, connection_status_t status) {
    assert(wii < WIIMOTE_COUNT);
    debug(PSTR("wii %d connection state change: %d\n"), wii, status);
    glb.connected[wii] = status;
    if (status == CONNECTED) {
        assert(wiiUserSetLeds(wii, _BV(wii), wii_leds_set) == SUCCESS);
    }

    draw_lcd();

    /* If any wiimotes are still disconnected, begin another connection attempt. */
    enum state st = GameRunning;
    for (uint8_t i = 0; i < WIIMOTE_COUNT; i++) {
        if (glb.connected[i] == DISCONNECTED) {
            assert(wiiUserConnect(i, wiimotes[i], wii_connection_change) == SUCCESS);
            st = GamePaused;
            break;
        }
    }

    /* MP3 playback, connection state is checked when done. */
    if (glb.st == PointScored) {
        return;
    }

    glb.st = st;
}

/**
 * Initializes all required subsystems.
 */
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

/**
 * Handles game movement, user input and game logic.
 */
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
    if (glb.ticks % 3 == 0) {
        for (uint8_t i = 0; i < WIIMOTE_COUNT; i++) {
            if (glb.buttons[i] & BtnUp) {
                pong_move(i, Up);
            }
            if (glb.buttons[i] & BtnDown) {
                pong_move(i, Down);
            }
        }
        pong_draw();
    }
}

/**
 * Sets the volume to the scaled ADC result if it has changed
 * at least ADC_SMOOTHING from the previous value.
 */
#define ADC_UPPER (1023)
#define ADC_SMOOTHING (20)
static void task_adc(void) {
    uint8_t vol = (glb.adc_result >= ADC_UPPER ? 0xFF : glb.adc_result / 4);
    if (abs(vol - glb.volume) > ADC_SMOOTHING) {
        mp3SetVolume(vol);
        glb.volume = vol;
        debug(PSTR("Volume: %d\n"), vol);
    }
}

/**
 * Container of all tasks. Executed once per main loop iteration.
 */
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

    debug(PSTR("AVR Pong starting up...\n"));
    lcd_putstr_P(PSTR("AVR Pong"), 0, 0);
    lcd_putstr_P(PSTR("Starting up..."), 1, 0);

    for (;;) {
        run_tasks();
        sleep_cpu();
    }

    return 0;
}

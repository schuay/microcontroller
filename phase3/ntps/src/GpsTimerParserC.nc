#include <stdlib.h>
#include <errno.h>
#include <limits.h>

module GpsTimerParserC
{
    uses interface StdControl as Uart;
    uses interface UartStream;
    uses interface UartControl;

    provides interface GpsTimerParser;
}

implementation
{
    command void GpsTimerParser.startService(void)
    {
        call Uart.start();

        call UartControl.setSpeed(4800);
        call UartControl.setParity(TOS_UART_PARITY_NONE);
    }

    command void GpsTimerParser.stopService(void)
    {
        call Uart.stop();
    }

#define MAX_FIELD_SIZE (6) /* The longest fields we care about are date/time. */

    static char buffer[MAX_FIELD_SIZE + 1]; /* Trailing '\0'. */
    static uint8_t buffer_pos = 0;

    static void buffer_push(char c)
    {
        if (buffer_pos == MAX_FIELD_SIZE) {
            return;
        }

        buffer[buffer_pos] = c;
        buffer_pos++;
    }

    static void buffer_clear(void)
    {
        memset(buffer, 0, MAX_FIELD_SIZE + 1);
        buffer_pos = 0;
    }

    static bool buffer_equals(const char *s)
    {
        return (strncmp(buffer, s, MAX_FIELD_SIZE) == 0);
    }

    static uint16_t parseint(const char *s, bool *ok)
    {
        char *endptr;
        uint16_t i;

        errno = 0;
        i = strtol(s, &endptr, 10);

        if ((errno == ERANGE && (i == LONG_MAX || i == LONG_MIN))
                || (errno != 0 && i == 0)) {
            *ok = FALSE;
            return 0;
        }

        if (endptr == s) {
            *ok = FALSE;
            return 0;
        }

        return i;
    }

#define STATE_INITIAL (0)
#define STATE_HEADER (1)
#define STATE_FIELDS (2)
#define STATE_END (3)
#define FIELD_TIME (0)
#define FIELD_DATE (8)

    /**
     * Implements a state machine to handle incoming gps sentences
     * Ignores all except sentences that are valid for us (GPRMC),
     * and fields we need (time and date).
     */
    async event void UartStream.receivedByte(uint8_t byte)
    {
        static uint8_t state = 0;
        static uint8_t field = 0;
        static timedate_t timedate;
        bool ok = TRUE;

        debug("Received: %d\r\n", byte);

        switch (state) {
        case STATE_INITIAL:
            switch (byte) {
            case '$':
                field = 0;
                state = STATE_HEADER;
                buffer_clear();
                break;
            default:
                break;
            }
            break;
        case STATE_HEADER:
            if (byte >= 'A' && byte <= 'z') {
                buffer_push(byte);
            } else if (byte == ',' && buffer_equals("GPRMC")) {
                state = STATE_FIELDS;
                buffer_clear();
            } else {
                state = STATE_INITIAL;
            }
            break;
        case STATE_FIELDS:
            switch (byte) {
            case '$':
                field = 0;
                state = STATE_HEADER;
                buffer_clear();
                break;
            case ',':
                /* Handle fields we care about here.
                 * Conversion errors reset the state machine.
                 */
                if (field == FIELD_TIME) {
                    timedate.time = parseint(buffer, &ok);
                } else if (field == FIELD_DATE) {
                    timedate.time = parseint(buffer, &ok);
                }

                if (!ok) {
                    state = STATE_INITIAL;
                } else {
                    field++;
                    buffer_clear();
                }
                break;
            case '\r':
                state = STATE_END;
                break;
            default:
                buffer_push(byte);
                break;
            }
            break;
        case STATE_END:
            switch (byte) {
            case '$':
                field = 0;
                state = STATE_HEADER;
                buffer_clear();
                break;
            case '\n':
                if (field >= FIELD_DATE) {
                    signal GpsTimerParser.newTimeDate(timedate);
                }
                state = STATE_INITIAL;
                break;
            default:
                state = STATE_INITIAL;
                break;
            }
            break;
        }
    }

    async event void UartStream.sendDone(uint8_t *buf __attribute__ ((unused)),
                                         uint16_t len __attribute__ ((unused)),
                                         error_t error __attribute ((unused)))
    {
        /* Nothing to send. */
    }

    async event void UartStream.receiveDone(uint8_t* buf __attribute__ ((unused)),
                                            uint16_t len __attribute__ ((unused)),
                                            error_t error __attribute__ ((unused)))
    {
        /* Not used. */
    }
}

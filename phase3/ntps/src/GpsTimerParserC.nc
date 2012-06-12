#include <stdlib.h>
#include <errno.h>
#include <limits.h>

#ifndef TEST
module GpsTimerParserC
{
    uses interface StdControl as Uart;
    uses interface UartStream;
    uses interface UartControl;
    uses interface Time;

    provides interface GpsTimerParser;
}

implementation
{
    command void GpsTimerParser.startService(void)
    {
        call Uart.start();

        call UartControl.setSpeed(4800);
        call UartControl.setParity(TOS_UART_PARITY_NONE);
        call UartStream.enableReceiveInterrupt();
    }

    command void GpsTimerParser.stopService(void)
    {
        call Uart.stop();
    }
#endif

#define MAX_FIELD_SIZE (6) /* The longest fields we care about are date/time. */

    static char buffer[MAX_FIELD_SIZE + 1]; /* Trailing '\0'. */
    static uint8_t buffer_pos = 0;

    /**
     * Appends c to the buffer unless the buffer is full.
     */
    static void buffer_push(char c)
    {
        if (buffer_pos == MAX_FIELD_SIZE) {
            return;
        }

        buffer[buffer_pos] = c;
        buffer_pos++;
    }

    /**
     * Clears the buffer.
     */
    static void buffer_clear(void)
    {
        memset(buffer, 0, MAX_FIELD_SIZE + 1);
        buffer_pos = 0;
    }

    /**
     * Returns true if the buffer contents equal s.
     * Only the filled part of the buffer is checked, and never more than
     * the buffer size. */
    static bool buffer_equals(const char *s)
    {
        /* TODO: Only check up to min(buffer_pos, MAX_FIELD_SIZE). */
        return (strncmp(buffer, s, MAX_FIELD_SIZE) == 0);
    }

    /**
     * Converts s to an unsigned integer and returns the result.
     * If a conversion error occurs, ok is set to FALSE.
     */
    static uint32_t parseint(const char *s, bool *ok)
    {
        char *endptr;
        unsigned long i;

        errno = 0;
        i = strtoul(s, &endptr, 10);

        if ((errno == ERANGE && i == ULONG_MAX) || (errno != 0 && i == 0)) {
            *ok = FALSE;
            return 0;
        }

        if (*endptr != '\0') {
            *ok = FALSE;
            return 0;
        }

        return i;
    }

    /**
     * Stores parsed time. 133542 represents 13:35:42.
     */
    static uint32_t time;

    /**
     * Stores parsed date. 230612 represents 23.6.2012.
     */
    static uint32_t date;

    /**
     * Converts the result of a GPS parsing run to timedate_t format.
     */
#ifndef TEST
    task void newTimeDateTask(void)
#else
    timedate_t testTimedate;
    void newTimeDateTask(void)
#endif
    {
        uint32_t t, d; /* Local copies of time and date. */
        timedate_t timedate;

#ifndef TEST
        atomic {
#endif
            t = time;
            d = date;
#ifndef TEST
        }
#endif

        timedate.seconds = t % 100;
        timedate.minutes = (t / 100) % 100;
        timedate.hours = t / 10000;

        timedate.year = d % 100;
        timedate.month = (d / 100) % 100;
        timedate.date = d / 10000;

#ifndef TEST
        timedate.day = call Time.dayOfWeek(timedate.date, timedate.month, timedate.year);

        signal GpsTimerParser.newTimeDate(timedate);
#else
        timedate.day = dayOfWeek(timedate.date, timedate.month, timedate.year);

        testTimedate = timedate;
#endif
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
#ifndef TEST
    async event void UartStream.receivedByte(uint8_t byte)
#else
    void receivedByte(uint8_t byte)
#endif
    {
        static uint8_t state = 0;
        static uint8_t field = 0;
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
            } else if (byte == '$') {
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
                    time = parseint(buffer, &ok);
                } else if (field == FIELD_DATE) {
                    date = parseint(buffer, &ok);
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
                if (field > FIELD_DATE) {
#ifndef TEST
                    post newTimeDateTask();
#else
                    newTimeDateTask();
#endif
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

#ifndef TEST
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
#endif

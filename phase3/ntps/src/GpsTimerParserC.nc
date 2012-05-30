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
    static inline bool isLeapYear(uint16_t year)
    {
        /* A year is a leap year if it is evenly divisible by 4,
         * and either not evenly divisible by 100, or divisible by 400. */
        return (((year % 4) == 0)
                && (((year % 100) != 0) || ((year % 400) == 0)));
    }

    /**
     * Returns the day of the week (1 = Monday, 7 = Sunday).
     * The year argument only specifies the last 2 digits of the year,
     * it is assumed that the century == 2000-2099.
     * The algorithm is taken from
     * http://java.dzone.com/articles/algorithm-week-how-determine
     */
    static uint8_t dayOfWeek(uint8_t date, uint8_t month, uint8_t year)
    {
        const uint8_t dowCentury = 6;
        const uint8_t dowMonth[] = { 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5 };
        uint8_t monthNo;
        uint8_t day;

        assert(date > 0 && date < 32);
        assert(month > 0 && month < 13);
        assert(year < 100);


        /* Add dow_century, the last 2 digits of the year,
         * the last 2 digits of the year divided by 4, and the month number.
         *
         * For January and Febuary in leap years, the correct month number is
         * (dow_month + 6) % 7.
         *
         * The result % 7 is the day of the week, with 0 = Sunday and 6 = Saturday.
         */

        monthNo = dowMonth[month - 1];
        if (isLeapYear(2000 + year)) {
            monthNo = (monthNo + 6) % 7;
        }

        day = (dowCentury + year + year / 4 + monthNo) % 7;
        if (day == 0) {
            day = 7;
        }

        return day;
    }

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

    static uint32_t parseint(const char *s, bool *ok)
    {
        char *endptr;
        uint32_t i;

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

    /**
     * Stores parsed time. 133542 represents 13:35:42.
     */
    static uint32_t time;

    /**
     * Stores parsed date. 230612 represents 23.6.2012.
     */
    static uint32_t date;

    task void newTimeDateTask(void)
    {
        uint32_t t, d; /* Local copies of time and date. */
        timedate_t timedate;

        atomic {
            t = time;
            d = date;
        }

        timedate.seconds = t % 100;
        timedate.minutes = (t / 100) % 100;
        timedate.hours = t / 10000;

        timedate.year = d % 100;
        timedate.month = (d / 100) % 100;
        timedate.date = d / 10000;

        timedate.day = dayOfWeek(timedate.date, timedate.month, timedate.year);

        signal GpsTimerParser.newTimeDate(timedate);
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
                if (field >= FIELD_DATE) {
                    post newTimeDateTask();
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

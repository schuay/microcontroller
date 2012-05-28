#include <assert.h>

module DS1307C
{
    provides interface Rtc;
    uses interface HplDS1307 as Hpl;
}

#define STATE_INITIAL (0)
#define STATE_START_READ (1)
#define STATE_START_WRITE (2)
#define STATE_GET_TIME (3)
#define STATE_STOP_READ (4)
#define STATE_STOP_WRITE (5)

implementation
{
    static ds1307_time_mem_t registerBuffer;
    static rtc_time_t *timePtr;
    static uint8_t state = STATE_INITIAL;

    static inline uint8_t fromBCD(uint8_t from, uint8_t mask)
    {
        return ((from >> 4) & mask) * 10 + (from & 0b1111);
    }

    static inline uint8_t toBCD(uint8_t from)
    {
        return ((from / 10) << 4) + (from % 10);
    }

    /**
     * Sets the time in dst to the values from src.
     */
    static void toRtcT(const ds1307_time_mem_t *src, rtc_time_t *dst)
    {
        assert(src);
        assert(dst);

        dst->seconds = fromBCD(src->seconds, 0b111);
        dst->minutes = fromBCD(src->minutes, 0b111);
        dst->hours = fromBCD(src->hours, 0b11);
        dst->day = fromBCD(src->day, 0b0);
        dst->date = fromBCD(src->date, 0b11);
        dst->month = fromBCD(src->month, 0b1);
        dst->year = fromBCD(src->year, 0b1111);
    }

    /**
     * Overwrites time locations in dst with the values from src.
     * Other locations remain unchanged.
     */
    static void toDS1307T(const rtc_time_t *src, ds1307_time_mem_t *dst)
    {
        assert(src);
        assert(dst);

        dst->seconds = toBCD(src->seconds);
        dst->minutes = toBCD(src->minutes);
        dst->hours = toBCD(src->hours);
        dst->day = toBCD(src->day);
        dst->date = toBCD(src->date);
        dst->month = toBCD(src->month);
        dst->year = toBCD(src->year);
    }

    command error_t Rtc.start(rtc_time_t *data)
    {
        debug("%s\r", __PRETTY_FUNCTION__);

        if (call Hpl.open() != SUCCESS) {
            return FAIL;
        }

        timePtr = data;
        state = STATE_START_READ;

        if (call Hpl.bulkRead(&registerBuffer) != SUCCESS) {
            state = STATE_INITIAL;
            call Hpl.close();
            return FAIL;
        };

        return SUCCESS;
    }

    command error_t Rtc.stop(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);

        if (call Hpl.open() != SUCCESS) {
            return FAIL;
        }

        state = STATE_STOP_READ;

        if (call Hpl.bulkRead(&registerBuffer) != SUCCESS) {
            state = STATE_INITIAL;
            call Hpl.close();
            return FAIL;
        };

        return SUCCESS;
    }

    command error_t Rtc.readTime(rtc_time_t *data)
    {
        assert(data);

        if (call Hpl.open() != SUCCESS) {
            return FAIL;
        }

        timePtr = data;
        state = STATE_GET_TIME;

        if (call Hpl.bulkRead(&registerBuffer) != SUCCESS) {
            state = STATE_INITIAL;
            call Hpl.close();
            return FAIL;
        };

        return SUCCESS;
    }

    async event void Hpl.registerReadReady(uint8_t value)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
    }

    async event void Hpl.registerWriteReady(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
    }

    task void bulkReadReadyTask(void)
    {
        switch (state) {
        case STATE_START_READ:
            if (timePtr) {
                /* Set the time as requested. */
                toDS1307T(timePtr, &registerBuffer);
            }

            /* Clear clock halt, set 24h mode. */
            registerBuffer.clockHalt = 0;
            registerBuffer.hour_mode = 0;

            state = STATE_START_WRITE;

            if (call Hpl.bulkWrite(&registerBuffer) != SUCCESS) {
                state = STATE_INITIAL;
                call Hpl.close();
            }
            break;
        case STATE_STOP_READ:
            /* Set clock halt. */
            registerBuffer.clockHalt = 1;

            state = STATE_STOP_WRITE;

            if (call Hpl.bulkWrite(&registerBuffer) != SUCCESS) {
                state = STATE_INITIAL;
                call Hpl.close();
            }
            break;
        case STATE_GET_TIME:
            toRtcT(&registerBuffer, timePtr);

            state = STATE_INITIAL;
            call Hpl.close();

            signal Rtc.timeReady();
            break;
        default:
            debug("Unexpected state %d\r", state);
            break;
        }
    }

    async event void Hpl.bulkReadReady(void)
    {
        if (post bulkReadReadyTask() != SUCCESS) {
            debug("post failed\r");
        }
    }

    task void bulkWriteReadyTask(void)
    {
        switch (state) {
        case STATE_START_WRITE:
        case STATE_STOP_WRITE:
            state = STATE_INITIAL;
            call Hpl.close();
            break;
        default:
            debug("Unexpected state %d\r", state);
            break;
        }
    }

    async event void Hpl.bulkWriteReady(void)
    {
        if (post bulkWriteReadyTask() != SUCCESS) {
            debug("post failed\r");
        }
    }
}

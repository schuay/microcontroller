#include <assert.h>

module DS1307C
{
    provides interface Rtc;
    uses interface HplDS1307;
}

#define STATE_INITIAL (0)

implementation
{
    static ds1307_time_mem_t registerBuffer;
    static uint8_t state = STATE_INITIAL;

    static void toRtcT(const ds1307_time_mem_t *src, rtc_time_t *dst)
    {
        assert(src);
        assert(dst);

        memset(dst, 0, sizeof(*dst));

        dst->seconds = src->seconds;
        dst->minutes = src->minutes;
        dst->hours = src->hours;
        dst->day = src->day;
        dst->date = src->date;
        dst->month = src->month;
        dst->year = src->year;
    }

    static void toDS1307T(const rtc_time_t *src, ds1307_time_mem_t *dst)
    {
        assert(src);
        assert(dst);

        memset(dst, 0, sizeof(*dst));

        dst->seconds = src->seconds;
        dst->minutes = src->minutes;
        dst->hours = src->hours;
        dst->day = src->day;
        dst->date = src->date;
        dst->month = src->month;
        dst->year = src->year;
    }

    command error_t Rtc.start(rtc_time_t *data)
    {
        if (call HplDS1307.open() != SUCCESS) {
            return FAIL;
        }

        return call HplDS1307.bulkRead(&registerBuffer);
    }

    command error_t Rtc.stop(void)
    {
        return FAIL;
    }

    command error_t Rtc.readTime(rtc_time_t *data)
    {
        return FAIL;
    }

    task void closeHpl(void)
    {
        call HplDS1307.close();
    }

    async event void HplDS1307.registerReadReady(uint8_t value)
    {
        debug("Received value from RTC: %x\r", value);
        post closeHpl();
    }

    async event void HplDS1307.registerWriteReady(void)
    {
    }

    async event void HplDS1307.bulkReadReady(void)
    {
    }

    async event void HplDS1307.bulkWriteReady(void)
    {
    }
}

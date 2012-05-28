#include <assert.h>

module DS1307C
{
    provides interface Rtc;
    uses interface HplDS1307 as Hpl;
}

#define STATE_INITIAL (0)

implementation
{
    static ds1307_time_mem_t registerBuffer;
    static uint8_t state = STATE_INITIAL;

    static inline uint8_t fromBCD(uint8_t from, uint8_t mask)
    {
        return (from >> 4) * 10 + (from & mask);
    }

    static inline uint8_t toBCD(uint8_t from)
    {
        return ((from / 10) << 4) + (from % 10);
    }

    static void toRtcT(const ds1307_time_mem_t *src, rtc_time_t *dst)
    {
        assert(src);
        assert(dst);

        memset(dst, 0, sizeof(*dst));

        dst->seconds = toBCD(src->seconds);
        dst->minutes = toBCD(src->minutes);
        dst->hours = toBCD(src->hours);
        dst->day = toBCD(src->day);
        dst->date = toBCD(src->date);
        dst->month = toBCD(src->month);
        dst->year = toBCD(src->year);
    }

    static void toDS1307T(const rtc_time_t *src, ds1307_time_mem_t *dst)
    {
        assert(src);
        assert(dst);

        memset(dst, 0, sizeof(*dst));

        dst->seconds = fromBCD(src->seconds, 0b111);
        dst->minutes = fromBCD(src->minutes, 0b111);
        dst->hours = fromBCD(src->hours, 0b11);
        dst->day = fromBCD(src->day, 0b0);
        dst->date = fromBCD(src->date, 0b11);
        dst->month = fromBCD(src->month, 0b1);
        dst->year = fromBCD(src->year, 0b1111);
    }

    command error_t Rtc.start(rtc_time_t *data)
    {
        debug("%s\r", __PRETTY_FUNCTION__);

        if (call Hpl.open() != SUCCESS) {
            return FAIL;
        }

        return call Hpl.bulkRead(&registerBuffer);
    }

    command error_t Rtc.stop(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        return FAIL;
    }

    command error_t Rtc.readTime(rtc_time_t *data)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        return FAIL;
    }

    task void closeHpl(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        call Hpl.close();
    }

    async event void Hpl.registerReadReady(uint8_t value)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        debug("Received value from RTC: %x\r", value);
        post closeHpl();
    }

    async event void Hpl.registerWriteReady(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
    }

    task void bulkReadReadyTask(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        debug("Secs %d Minutes %d Hours %d\r",
            fromBCD(registerBuffer.seconds, 0b111),
            fromBCD(registerBuffer.minutes, 0b111),
            fromBCD(registerBuffer.hours, 0b11));
    }

    async event void Hpl.bulkReadReady(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        post bulkReadReadyTask();
    }

    async event void Hpl.bulkWriteReady(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
    }
}

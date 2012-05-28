#include <Atm128Uart.h>
#include <assert.h>

module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
    uses interface GpsTimerParser;
    uses interface Rtc;
    uses interface Leds;
}

implementation
{
    static rtc_time_t time = { 0, 51, 15, 1, 1, 2, 10 };

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

    event void Boot.booted(void)
    {
        debug("%s\r\n", __PRETTY_FUNCTION__);
        debug("Node ID %d\r\n", TOS_NODE_ID);

        call UserInterface.init();
        call Rtc.start(&time);
        call GpsTimerParser.startService();

        /* TODO: use a timer for this. */
        call Rtc.readTime(&time);
    }

    event void UserInterface.setToGPSPressed(void)
    {
        debug("Set to GPS pressed.\r\n");
    }

    event void UserInterface.setToOffsetPressed(void)
    {
        debug("Set to Offset pressed.\r\n");
    }

    event void GpsTimerParser.newTimeDate(timedate_t newTimeDate)
    {
        debug("%s\r\n", __PRETTY_FUNCTION__);
        call UserInterface.setTimeGPS(newTimeDate);
    }

    event void Rtc.timeReady(void)
    {
        debug("%02d:%02d:%02d %02d.%02d.20%02d\r",
            time.hours, time.minutes, time.seconds,
            time.date, time.month, time.year);
        call UserInterface.setTimeRTC(time);
    }
}

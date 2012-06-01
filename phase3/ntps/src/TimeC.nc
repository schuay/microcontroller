module TimeC
{
    provides interface Time;
}

implementation
{
    static inline bool isLeapYear(uint16_t year)
    {
        /* A year is a leap year if it is evenly divisible by 4,
         * and either not evenly divisible by 100, or divisible by 400.
         */
        if (year % 4 != 0) {
            return FALSE;
        }

        if (year % 400 == 0) {
            return TRUE;
        }

        if (year % 100 == 0) {
            return FALSE;
        }

        return TRUE;
    }

    /**
     * The algorithm is taken from
     * http://java.dzone.com/articles/algorithm-week-how-determine
     */
    command uint8_t Time.dayOfWeek(uint8_t date, uint8_t month, uint8_t year)
    {
        const uint8_t dowCentury = 6;
        const uint8_t dowMonth[] = { 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5 };
        uint8_t monthNo;
        uint8_t day;

        assert(date > 0 && date < 32);
        assert(month > 0 && month < 13);
        assert(year < 100);


        /* Add dow_century, the last 2 digits of the year,
         * the last 2 digits of the year divided by 4, the month number, and the
         * date.
         *
         * For January and Febuary in leap years, the correct month number is
         * (dow_month + 6) % 7.
         *
         * The result % 7 is the day of the week, with 0 = Sunday and 6 = Saturday.
         */

        monthNo = dowMonth[month - 1];
        if (isLeapYear(2000 + year) && month < 3) {
            monthNo = (monthNo + 6) % 7;
        }

        day = (dowCentury + year + year / 4 + monthNo + date) % 7;
        if (day == 0) {
            day = 7;
        }

        return day;
    }

    command void Time.toNtpTimestamp(uint32_t *dst, const rtc_time_t *src)
    {
    }

    command void Time.fromNtpTimestamp(rtc_time_t *dst, const uint32_t *src)
    {
    }
}

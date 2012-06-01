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

#define TIMESTAMP_01012000 (3155673600UL)
#define SECS_PER_MINUTE (60UL)
#define SECS_PER_HOUR (SECS_PER_MINUTE * 60UL)
#define SECS_PER_DAY (SECS_PER_HOUR * 24UL)
#define SECS_PER_YEAR (SECS_PER_DAY * 365UL)

    command void Time.toNtpTimestamp(uint32_t *dst, const rtc_time_t *src)
    {
        uint32_t ts = TIMESTAMP_01012000;
        uint8_t days_in_year[] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 };
        uint8_t i;

        /* Sum up days_in_year. */
        for (i = 2; i < sizeof(days_in_year) / sizeof(days_in_year[0]); i++) {
            days_in_year[i] += days_in_year[i - 1];
        }

        /* Note: 2000 is represented as 0. */
        ts += SECS_PER_YEAR * src->year;

        /* Add a day for each leap year which occurred between 2000 and src->year.
         * ((...) + 1) because 2000 itself is a leap year. */
        ts += SECS_PER_DAY * ((src->year / 4) + 1);

        /* The previous calculation also adds a day if the current year is a leap year.
         * If however src->month < 3, this is incorrect and we need to subtract it. */
        if (isLeapYear(src->year) && src->month < 3) {
            ts -= SECS_PER_DAY;
        }

        ts += SECS_PER_DAY * days_in_year[src->month - 1];
        ts += SECS_PER_DAY * (src->date - 1);
        ts += SECS_PER_HOUR * src->hours;
        ts += SECS_PER_MINUTE * src->minutes;
        ts += src->seconds;

        *dst = ts;
    }

    command void Time.fromNtpTimestamp(rtc_time_t *dst, const uint32_t *src)
    {
    }
}

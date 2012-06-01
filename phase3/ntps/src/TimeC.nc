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
#define MINS_PER_HOUR (60UL)
#define HOURS_PER_DAY (24UL)
#define DAYS_PER_YEAR (365UL)
#define MONTHS_PER_YEAR (12UL)
#define SECS_PER_MINUTE (60UL)
#define SECS_PER_HOUR (SECS_PER_MINUTE * MINS_PER_HOUR)
#define SECS_PER_DAY (SECS_PER_HOUR * HOURS_PER_DAY)
#define SECS_PER_YEAR (SECS_PER_DAY * DAYS_PER_YEAR)

    /* Stores sum of days in year in previous months.
     * Cumulative sum of: { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 }
     */
    static const uint16_t days_until_month[] =
        { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

    command void Time.toNtpTimestamp(uint32_t *dst, const rtc_time_t *src)
    {
        uint32_t ts = TIMESTAMP_01012000;

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

        ts += SECS_PER_DAY * days_until_month[src->month - 1];
        ts += SECS_PER_DAY * (src->date - 1);
        ts += SECS_PER_HOUR * src->hours;
        ts += SECS_PER_MINUTE * src->minutes;
        ts += src->seconds;

        *dst = ts;
    }

    command void Time.fromNtpTimestamp(rtc_time_t *dst, const uint32_t *src)
    {
        uint32_t ts = *src - TIMESTAMP_01012000;
        uint16_t days_in_year;

        dst->seconds = ts % SECS_PER_MINUTE;
        ts /= SECS_PER_MINUTE;

        dst->minutes = ts % MINS_PER_HOUR;
        ts /= MINS_PER_HOUR;

        dst->hours = ts % HOURS_PER_DAY;
        ts /= HOURS_PER_DAY;

        /* ts is now a count of days. */

        for (dst->year = 0; ; dst->year++) {
            days_in_year = DAYS_PER_YEAR;
            if (isLeapYear(dst->year)) {
                days_in_year++;
            }
            if (days_in_year > ts) {
                break;
            } else {
                ts -= days_in_year;
            }
        }

        /* dst->year is now set correctly, and ts is the count of days passed in current year. */

        for (dst->month = 1; dst->month < MONTHS_PER_YEAR; dst->month++) {
            if (days_until_month[dst->month] > ts) {
                break;
            }
        }
        ts -= days_until_month[dst->month - 1];

        dst->date = ts;

        dst->day = call Time.dayOfWeek(dst->date, dst->month, dst->year);
    }
}

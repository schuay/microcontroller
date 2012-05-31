/**
 * Combining the restrictions given by the specification (2000-2050)
 * and the NTP timestamp era rollover (2036), the supported time range is
 * 2000 - 2036.
 */
interface Time
{
    /**
     * Returns the day of the week (1 = Monday, 7 = Sunday).
     * The year argument only specifies the last 2 digits of the year,
     * it is assumed that the century == 2000-2099.
     */
    command uint8_t dayOfWeek(uint8_t date, uint8_t month, uint8_t year);

    /**
     * Converts src to an NTP timestamp (the count of seconds since Jan 1st 1900).
     * The result is suitable for usage in the seconds field of the NTP Timestamp Format.
     * Note that the result is still in host byte order.
     */
    command void toNtpTimestamp(uint32_t *dst, const rtc_time_t *src);

    /**
     * Converts src (the seconds field of the NTP Timestamp Format in host byte order)
     * into an rtc_time_t.
     */
    command void fromNtpTimestamp(rtc_time_t *dst, const uint32_t *src);
}

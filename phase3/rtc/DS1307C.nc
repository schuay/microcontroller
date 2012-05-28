module DS1307C
{
    provides interface Rtc;
    uses interface HplDS1307;
}

implementation
{
    command error_t start(rtc_time_t *data)
    {
    }

    command error_t stop(void)
    {
    }

    command error_t readTime(rtc_time_t *data)
    {
    }
}

module RtcDemoC
{
    uses interface Boot;
    uses interface Leds;
    uses interface Rtc;
    uses interface Timer<TMilli> as Timer;
}

implementation
{
    static rtc_time_t time;

    event void Boot.booted(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        debug("Node ID %d\r", TOS_NODE_ID);

        call Rtc.start(&time);
        call Timer.startPeriodic(1000);
    }

    event void Rtc.timeReady(void)
    {
        debug("%02d:%02d:%02d %02d.%02d.20%02d\r",
            time.hours, time.minutes, time.seconds,
            time.date, time.month, time.year);
    }

    event void Timer.fired()
    {
        call Rtc.readTime(&time);
    }
}

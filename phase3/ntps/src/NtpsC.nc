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

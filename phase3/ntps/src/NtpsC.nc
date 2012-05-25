#include <Atm128Uart.h>

#include "GpsTimerParser.h"

module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
    uses interface GpsTimerParser;
    uses interface Leds;
}

implementation
{
    event void Boot.booted(void)
    {
        timedate_t gps_time;
        rtc_time_t rtc_time;

        debug("%s\r\n", __PRETTY_FUNCTION__);
        debug("Node ID %d\r\n", TOS_NODE_ID);

        call UserInterface.init();

        /* TODO */
        call UserInterface.setTimeGPS(gps_time);
        call UserInterface.setTimeRTC(rtc_time);

        call GpsTimerParser.startService();
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
}

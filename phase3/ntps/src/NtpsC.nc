module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
}

implementation
{
    event void Boot.booted(void)
    {
        timedate_t gps_time;
        rtc_time_t rtc_time;

        printf_P(PSTR("%s\r\n"), __PRETTY_FUNCTION__);
        printf_P(PSTR("Node ID %d\r\n"), TOS_NODE_ID);

        call UserInterface.init();

        /* TODO */
        call UserInterface.setTimeGPS(gps_time);
        call UserInterface.setTimeRTC(rtc_time);
    }

    event void UserInterface.setToGPSPressed(void)
    {
        printf_P(PSTR("Set to GPS pressed.\r\n"));
    }

    event void UserInterface.setToOffsetPressed(void)
    {
        printf_P(PSTR("Set to Offset pressed.\r\n"));
    }
}

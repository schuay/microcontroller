module NtpsC
{
    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface UserInterface;
}

implementation
{
    event void Boot.booted()
    {
        printf_P(PSTR("%s\r\n"), __PRETTY_FUNCTION__);
        printf_P(PSTR("Node ID %d\r\n"), TOS_NODE_ID);

        call Timer.startPeriodic(500);
    }

    event void Timer.fired()
    {
        call UserInterface.setTimeGPS("ABCDE");
    }
}

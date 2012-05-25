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
        debug("booted");
        call Timer.startPeriodic(500);

        printf("Hallo ");
        printf_P(PSTR("Du!\n"));

        printf("my node id is %d\n", TOS_NODE_ID);
    }

    event void Timer.fired()
    {
        static const char *str = "ABCDE";
        static uint8_t c = 0;
        c++;

        debug("fired: %d", c);
        printf_P(PSTR("Counter: %03d (0x%02X)\n"), c, c);
        call UserInterface.setTimeGPS(str);
    }
}

module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
}

implementation
{
    event void Boot.booted(void)
    {
        printf_P(PSTR("%s\r\n"), __PRETTY_FUNCTION__);
        printf_P(PSTR("Node ID %d\r\n"), TOS_NODE_ID);

        call UserInterface.init();
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

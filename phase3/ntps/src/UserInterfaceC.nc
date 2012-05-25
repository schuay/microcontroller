module UserInterfaceC
{
    uses interface TouchScreen;
    uses interface Glcd;
    provides interface UserInterface;
}

implementation
{
    command void UserInterface.setTimeGPS(const char *str)
    {
        call Glcd.fill(0x00);
        call Glcd.drawText(str, 20, 20);
    }

    event void TouchScreen.coordinatesReady(void)
    {
        debug("coordinatesReady");
    }
}

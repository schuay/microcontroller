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
        call Glcd.drawText(str, 20, 20);
    }

    event void TouchScreen.coordinatesReady(void)
    {
		debug("Demo: x=%u \t y=%u\n\r", coordinates.x, coordinates.y);
    }
}

module UserInterfaceC
{
    uses interface TouchScreen;
    uses interface Glcd;
    provides interface UserInterface;
}

#define GLCD_MAX_X (127)
#define GLCD_MAX_Y (63)
#define LETTER_WIDTH (6)
#define LETTER_HEIGHT (7)

implementation
{
    command void UserInterface.init(void)
    {
        const int mid_y = GLCD_MAX_Y / 2;
        const int mid_x = GLCD_MAX_X / 2;
        const char *labelSet = "Set to";
        const char *labelGPS = "GPS";
        const char *labelOffset = "Offset";

        call Glcd.fill(0x00);

        /* Button frames. */
        call Glcd.drawRect(0, 0, GLCD_MAX_X, mid_y);
        call Glcd.drawLine(mid_x, 0, mid_x, mid_y);

        /* Labels. */
        call Glcd.drawText(labelSet, (mid_x - LETTER_WIDTH * strlen(labelSet)) / 2, 15);
        call Glcd.drawText(labelSet, mid_x + (mid_x - LETTER_WIDTH * strlen(labelSet)) / 2, 15);

        call Glcd.drawText(labelGPS, (mid_x - LETTER_WIDTH * strlen(labelGPS)) / 2, 25);
        call Glcd.drawText(labelOffset,
                           mid_x + (mid_x - LETTER_WIDTH * strlen(labelOffset)) / 2, 25);
    }

    command void UserInterface.setTimeGPS(const char *str)
    {
        call Glcd.drawText(str, 20, 50);
    }

    event void TouchScreen.coordinatesReady(void)
    {
        debug("coordinatesReady");
    }
}

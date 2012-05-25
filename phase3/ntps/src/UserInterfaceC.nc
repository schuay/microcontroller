module UserInterfaceC
{
    uses interface TouchScreen;
    uses interface Glcd;
    uses interface Timer<TMilli> as Timer;

    provides interface UserInterface;
}

#define GLCD_MAX_X (127)
#define GLCD_MAX_Y (63)
#define LETTER_WIDTH (6)
#define LETTER_HEIGHT (7)
#define POLL_INTERVAL_MS (50)

#define BTN_GPS_X0 (0)
#define BTN_GPS_Y0 (0)
#define BTN_GPS_X1 (GLCD_MAX_X / 2)
#define BTN_GPS_Y1 (GLCD_MAX_Y / 2)

#define BTN_OFS_X0 (BTN_GPS_X1)
#define BTN_OFS_Y0 (BTN_GPS_Y0)
#define BTN_OFS_X1 (GLCD_MAX_X)
#define BTN_OFS_Y1 (BTN_GPS_Y1)

implementation
{
    ts_coordinates_t coordinates;

    command void UserInterface.init(void)
    {
        const char *labelSet = "Set to";
        const char *labelGPS = "GPS";
        const char *labelOffset = "Offset";

        call Glcd.fill(0x00);

        /* Button frames. */
        call Glcd.drawRect(BTN_GPS_X0, BTN_GPS_Y0, BTN_GPS_X1, BTN_GPS_Y1);
        call Glcd.drawRect(BTN_OFS_X0, BTN_OFS_Y0, BTN_OFS_X1, BTN_OFS_Y1);

        /* Labels. */
        call Glcd.drawText(labelSet, (BTN_GPS_X1 - LETTER_WIDTH * strlen(labelSet)) / 2, 15);
        call Glcd.drawText(labelSet,
                           BTN_OFS_X0 + (BTN_GPS_X1 - LETTER_WIDTH * strlen(labelSet)) / 2, 15);

        call Glcd.drawText(labelGPS, (BTN_GPS_X1 - LETTER_WIDTH * strlen(labelGPS)) / 2, 25);
        call Glcd.drawText(labelOffset,
                           BTN_OFS_X0 + (BTN_OFS_X0 - LETTER_WIDTH * strlen(labelOffset)) / 2, 25);

        /* Begin polling touchscreen. */
        call Timer.startPeriodic(POLL_INTERVAL_MS);
    }

    command void UserInterface.setTimeGPS(const char *str)
    {
        call Glcd.drawText(str, 20, 50);
    }

    event void TouchScreen.coordinatesReady(void)
    {
        if (coordinates.x < BTN_GPS_X1 && coordinates.y < BTN_GPS_Y1) {
            signal UserInterface.setToGPSPressed();
        } else if (coordinates.x < BTN_OFS_X1 && coordinates.y < BTN_OFS_Y1) {
            signal UserInterface.setToOffsetPressed();
        }
    }

    event void Timer.fired()
    {
        call TouchScreen.getCoordinates(&coordinates);
    }
}

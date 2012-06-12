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
#define LETTER_HEIGHT (8)
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
    /** Stores last read touchscreen coordinates. */
    static ts_coordinates_t coordinates;

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


#define MAX_STR_LEN (20) /* For example, "GPS: Tue 22.05.2012". */

    /* Holds the strings to print to the GLCD. */
    static char stringBuffer[MAX_STR_LEN];

    /** Not stored in PROGMEM because GLCD functions cannot handle PROGMEM types. */
    static const char *dayNames[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
    static const char *dayName(uint8_t day)
    {
        return dayNames[day % 7];
    }

    command void UserInterface.setTimeGPS(timedate_t time)
    {
        snprintf_P(stringBuffer, MAX_STR_LEN, PSTR("GPS: %s %02d.%02d.20%02d"),
                   dayName(time.day), time.date, time.month, time.year);
        call Glcd.drawText(stringBuffer, 2, BTN_GPS_Y1 + 1 + LETTER_HEIGHT * 1);

        snprintf_P(stringBuffer, MAX_STR_LEN, PSTR("           %02d:%02d:%02d"),
                   time.hours, time.minutes, time.seconds);
        call Glcd.drawText(stringBuffer, 2, BTN_GPS_Y1 + 1 + LETTER_HEIGHT * 2);
    }

    command void UserInterface.setTimeRTC(rtc_time_t time)
    {
        snprintf_P(stringBuffer, MAX_STR_LEN, PSTR("RTC: %s %02d.%02d.20%02d"),
                   dayName(time.day), time.date, time.month, time.year);
        call Glcd.drawText(stringBuffer, 2, BTN_GPS_Y1 + 1 + LETTER_HEIGHT * 3);

        snprintf_P(stringBuffer, MAX_STR_LEN, PSTR("           %02d:%02d:%02d"),
                   time.hours, time.minutes, time.seconds);
        call Glcd.drawText(stringBuffer, 2, BTN_GPS_Y1 + 1 + LETTER_HEIGHT * 4);
    }

    event void TouchScreen.coordinatesReady(void)
    {
        if (coordinates.x < BTN_GPS_X1 && coordinates.y < BTN_GPS_Y1) {
            signal UserInterface.setToGPSPressed();
        } else if (coordinates.x < BTN_OFS_X1 && coordinates.y < BTN_OFS_Y1) {
            signal UserInterface.setToOffsetPressed();
        }
    }

    /** Poll touchscreen on each timer tick. */
    event void Timer.fired()
    {
        call TouchScreen.getCoordinates(&coordinates);
    }
}

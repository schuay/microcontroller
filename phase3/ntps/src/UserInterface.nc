#include "GpsTimerParser.h"
#include "Rtc.h"

interface UserInterface
{
    /**
     * Draws buttons to the GLCD.
     */
    command void init(void);

    /**
     * Updates the displayed GPS time.
     */
    command void setTimeGPS(timedate_t time);

    /**
     * Updates the displayed RTC time.
     */
    command void setTimeRTC(rtc_time_t time);

    /**
     * The 'Set to GPS' button has been pressed.
     */
    event void setToGPSPressed(void);

    /**
     * The 'Set to Offset' button has been pressed.
     */
    event void setToOffsetPressed(void);
}

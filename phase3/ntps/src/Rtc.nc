#include "Rtc.h"

interface Rtc
{
    /**
     * Starts the realtime clock.
     * @param data Starts the clock, setting date/time.
     *             If NULL is passed, the clock is started without
     *             changing anything.
     * @return SUCCESS if bus available and request accepted.
     */
    command error_t start(rtc_time_t *data);

    /**
     * Stops the realtime clock without changing the time.
     */
    command error_t stop(void);

    command error_t readTime(rtc_time_t *data);
    event void timeReady(void);
}

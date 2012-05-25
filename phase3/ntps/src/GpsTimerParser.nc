interface GpsTime
{
    /**
     ∗ Starts the parsing service of the GPS output stream.
     */
    command void startService(void);

    /**
     * Stops the parsing service of the GPS output stream.
     */
    command void stopService(void);

    /**
     * Notification that a time and date was parsed.
     */
    event void newTimeDate(timedate_t newTimeDate);
}


interface UserInterface
{
    /**
     * Draws buttons to the GLCD.
     */
    command void init(void);

    /**
     * Updates the displayed GPS time.
     */
    command void setTimeGPS(const char *str);

    /**
     * The 'Set to GPS' button has been pressed.
     */
    event void setToGPSPressed(void);

    /**
     * The 'Set to Offset' button has been pressed.
     */
    event void setToOffsetPressed(void);
}

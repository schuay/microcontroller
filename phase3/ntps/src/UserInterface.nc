interface UserInterface
{
    /**
     * Draws buttons to the GLCD.
     */
    command void init(void);

    command void setTimeGPS(const char *str);
}

module RtcC
{
    uses interface Boot;
    uses interface Leds;
}

implementation
{
    event void Boot.booted(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        debug("Node ID %d\r", TOS_NODE_ID);
    }
}

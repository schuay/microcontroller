module RtcC
{
    uses interface Boot;
    uses interface Leds;
    uses interface HplDS1307;
}

implementation
{
    event void Boot.booted(void)
    {
        debug("%s\r", __PRETTY_FUNCTION__);
        debug("Node ID %d\r", TOS_NODE_ID);
    }

    async event void HplDS1307.registerReadReady(uint8_t value)
    {
    }

    async event void HplDS1307.registerWriteReady(void)
    {
    }

    async event void HplDS1307.bulkReadReady(void)
    {
    }

    async event void HplDS1307.bulkWriteReady(void)
    {
    }
}

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

        call HplDS1307.open();
        call HplDS1307.registerRead(0x00);
    }

    task void closeHpl(void)
    {
        call HplDS1307.close();
    }

    async event void HplDS1307.registerReadReady(uint8_t value)
    {
        debug("Received value from RTC: %x\r", value);
        post closeHpl();
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

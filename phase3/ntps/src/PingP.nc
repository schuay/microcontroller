module PingP
{
	uses interface IcmpReceive;
	uses interface IcmpSend;
}

implementation
{
#define TYPE_ECHO_REPLY (0)
#define PING_MAX_DATA (100)

    static uint8_t pingData[PING_MAX_DATA];
    static in_addr_t pingIp;

    /**
     * Replies to received ping packets.
     * The reply packet includes up to 100 bytes of the original packet.
     */
	event void IcmpReceive.received(in_addr_t *srcIp, uint8_t code, uint8_t *data, uint16_t len)
    {
        memcpy(pingData, data, len < PING_MAX_DATA ? len : PING_MAX_DATA);
        memcpy(&pingIp, srcIp, sizeof(pingIp));

        call IcmpSend.send(&pingIp, TYPE_ECHO_REPLY, code, pingData, len);
	}
	
	event void IcmpSend.sendDone(error_t error)
    {
        /* Ignored. */
	}
}

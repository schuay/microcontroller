module PingP
{
	uses interface IcmpReceive;
	uses interface IcmpSend;
}

implementation
{
#define TYPE_ECHO_REPLY (0)
	static uint8_t pingData[100];
    static in_addr_t pingIp;

	event void IcmpReceive.received(in_addr_t *srcIp, uint8_t code, uint8_t *data, uint16_t len)
    {
        memcpy(pingData, data, len < 100 ? len : 100);
        memcpy(&pingIp, srcIp, sizeof(pingIp));

        call IcmpSend.send(&pingIp, TYPE_ECHO_REPLY, code, pingData, len);
	}
	
	event void IcmpSend.sendDone(error_t error)
    {
	}
}

#include "ping.h"

configuration PingC
{
}

implementation
{
	components new IcmpC(ICMP_TYPE_ECHO_REQUEST) as IcmpC;
	components PingP;
	
	PingP.IcmpSend -> IcmpC.IcmpSend;
	PingP.IcmpReceive -> IcmpC.IcmpReceive;
}

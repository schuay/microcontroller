/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ping.h"

configuration PingC {

}

implementation {
	components new IcmpC(ICMP_TYPE_ECHO_REQUEST) as IcmpC;
	components PingP;
	
	PingP.IcmpSend -> IcmpC.IcmpSend;
	PingP.IcmpReceive -> IcmpC.IcmpReceive;
}
/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"

configuration IcmpTransceiverC {
	provides interface PacketSender<icmp_queue_item_t> @exactlyonce();
	provides interface IcmpReceive[uint8_t type];
}

implementation {
	components new IpC(IP_PROTOCOL_ICMP);
	components IcmpTransceiverP;
	
	IcmpTransceiverP.PacketSender = PacketSender;
	IcmpTransceiverP.IcmpReceive = IcmpReceive;
	IcmpTransceiverP.IpReceive -> IpC.IpReceive;
	IcmpTransceiverP.IpSend -> IpC.IpSend;
}

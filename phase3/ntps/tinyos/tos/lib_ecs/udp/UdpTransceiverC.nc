/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"

configuration UdpTransceiverC {
	provides interface PacketSender<udp_queue_item_t> @exactlyonce();
	provides interface UdpReceive[uint16_t port];
}

implementation {
	components new IpC(IP_PROTOCOL_UDP);
	components IpTransceiverC;
	components UdpTransceiverP;
	
	UdpTransceiverP.PacketSender = PacketSender;
	UdpTransceiverP.UdpReceive = UdpReceive;
	UdpTransceiverP.IpReceive -> IpC.IpReceive;
	UdpTransceiverP.IpSend -> IpC.IpSend;
	UdpTransceiverP.IpPacket -> IpTransceiverC.IpPacket;
}

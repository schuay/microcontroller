/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ip.h"

configuration IpTransceiverC {
	provides interface PacketSender<ip_queue_item_t> @exactlyonce();
	provides interface IpReceive[uint8_t protocol];
	provides interface IpControl;
	provides interface IpPacket;
}

implementation {
	components IpTransceiverP;
	components new LlcC(ETHER_TYPE_IPV4);
	components ArpC;
	components MainC;
	components PingC;

	IpTransceiverP.PacketSender = PacketSender;
	IpTransceiverP.IpReceive = IpReceive;
	IpTransceiverP.LlcSend -> LlcC.LlcSend;
	IpTransceiverP.LlcReceive -> LlcC.LlcReceive;
	IpTransceiverP.IpControl = IpControl;
	IpTransceiverP.Arp -> ArpC.Arp;
	ArpC.IpControl -> IpTransceiverP.IpControl;
	IpTransceiverP.Init <- MainC.SoftwareInit;
	IpTransceiverP.IpPacket = IpPacket;
}

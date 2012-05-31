/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"

module UdpTransceiverP {
	provides interface PacketSender<udp_queue_item_t>;
	provides interface UdpReceive[uint16_t port];
	uses interface IpSend;
	uses interface IpReceive;
	uses interface IpPacket;
    uses interface IcmpSend;
}

implementation {
	
	udp_packet_t packet;
	
	command error_t PacketSender.send(udp_queue_item_t *item) {
		// create udp packet
		
		packet.header.srcPort = item->srcPort;
		packet.header.dstPort = item->dstPort;
		packet.header.len = item->dataLen + sizeof(udp_header_t);
		memcpy(&(packet.data), item->data, item->dataLen);
		
		return call IpSend.send(&(item->dstIp), (uint8_t*)&(packet), packet.header.len);
	}
	
#define TYPE_HOST_UNREACHABLE (3)
#define CODE_HOST_UNREACHABLE (3)
	static uint8_t icmpData[100];
    static in_addr_t icmpIp;
	default event void UdpReceive.received[uint16_t port](in_addr_t *srcIp, uint16_t srcPort, uint8_t *data, uint16_t len) {
		/* there is no module associated with the port on which the message was received */
		/* discard the message */
        ip_packet_t *ipPacket = call IpPacket.getPacket();
        uint8_t l = sizeof(ip_header_t) + 8;

        /* + 4 because of unused and MTU sections. */
        memset(icmpData, 0, sizeof(icmpData));
        memcpy(icmpData + 4, ipPacket, l);
        memcpy(&icmpIp, srcIp, sizeof(icmpIp));

        call IcmpSend.send(&icmpIp, TYPE_HOST_UNREACHABLE, CODE_HOST_UNREACHABLE, icmpData, l);
	}
	
	event void IcmpSend.sendDone(error_t error)
    {
	}
		
	event void IpReceive.received(in_addr_t *srcIp, uint8_t *data, uint16_t len) {
		udp_packet_t *p = (udp_packet_t*)data;
		
		signal UdpReceive.received[p->header.dstPort](srcIp, p->header.srcPort, (uint8_t*)&(p->data), p->header.len - sizeof(udp_header_t));
	}

	event void IpSend.sendDone(error_t error) {
		signal PacketSender.sendDone(error);
	}
}

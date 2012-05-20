/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"

module IcmpTransceiverP {
	provides interface PacketSender<icmp_queue_item_t>;
	provides interface IcmpReceive[uint8_t type];
	uses interface IpSend;
	uses interface IpReceive;
}

implementation {
	icmp_packet_t packet;
	
	uint16_t icmp_checksum(icmp_packet_t *_packet, uint16_t len) {
		uint32_t sum = 0;
		uint16_t word16 = 0, i = 0, *tmpPtr;

		tmpPtr = (uint16_t*)_packet;

		// make 16 bit words out of every two adjacent 8 bit words in the packet
		// and add them up. we use 16bit - pointers, so we can iterate over the
		// 20byte - ip-header in just 10 loops.
		for (i=0;i<len/2;i++) {
			word16 =(( (*(tmpPtr+i)) & (0xFF00)) +( (*(tmpPtr+i)) & 0xFF));
			sum = sum + (uint32_t) word16;	
		}
	
		// take only 16 bits out of the 32 bit sum and add up the carries
		while (sum>>16) {
		  sum = (sum & 0xFFFF)+(sum >> 16);
		}

		// one's complement the result
		sum = ~sum;
		return (uint16_t)sum;
	}
	
	command error_t PacketSender.send(icmp_queue_item_t *item) {
		// create icmp packet
		uint16_t packetLen = item->dataLen + sizeof(icmp_header_t);
		
		packet.header.type = item->type;
		packet.header.code = item->code;
		memcpy(&(packet.data), item->data, item->dataLen);
		packet.header.checksum = 0;
		packet.header.checksum = icmp_checksum(&packet, packetLen);
		
		return call IpSend.send(&(item->dstIp), (uint8_t*)&(packet), packetLen);
	}
	
	default event void IcmpReceive.received[uint8_t type](in_addr_t *srcIp, uint8_t code, uint8_t *data, uint16_t len) {
		// unknown type, drop packet
	}
	
	event void IpReceive.received(in_addr_t *srcIp, uint8_t *data, uint16_t len) {
		icmp_packet_t *p = (icmp_packet_t*)data;
		
		signal IcmpReceive.received[p->header.type](srcIp, p->header.code, (uint8_t*)&(p->data), len - sizeof(icmp_header_t));
	}

	event void IpSend.sendDone(error_t error) {
		signal PacketSender.sendDone(error);
	}
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ip.h"
#include "mac.h"

module IpTransceiverP {
	provides interface PacketSender<ip_queue_item_t>;
	provides interface IpReceive[uint8_t protocol];
	provides interface IpControl;
	uses interface LlcSend;
	uses interface LlcReceive;
	uses interface Arp;
	provides interface Init;
	provides interface IpPacket;
}

implementation {
	in_addr_t myIp = { .bytes {10, 60, 0, 10}};
	in_addr_t gateway = { .bytes {10, 60, 0, 1}};
	in_addr_t netmask = { .bytes {255, 255, 0, 0}};
	ip_packet_t packet;
	ip_packet_t *currentReceivedPacket;

	uint16_t header_checksum(ip_packet_t *_packet) {
		uint32_t sum = 0;
		uint16_t word16 = 0, i = 0, *tmpPtr;

		tmpPtr = (uint16_t*)_packet;

		// make 16 bit words out of every two adjacent 8 bit words in the packet
		// and add them up. we use 16bit - pointers, so we can iterate over the
		// 20byte - ip-header in just 10 loops.
		for (i=0;i<10;i++) {
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

	command ip_packet_t* IpPacket.getPacket() {
		return currentReceivedPacket;
	}

	command error_t Init.init() {
		myIp.bytes.b3 = TOS_NODE_ID >> 8;
		myIp.bytes.b4 = TOS_NODE_ID & 0xff;
		return SUCCESS;
	}

	command void IpControl.setIp(in_addr_t *ip) {
		myIp = *ip;
	}

	command void IpControl.setGateway(in_addr_t *_gateway) {
		gateway = *_gateway;
	}

	command void IpControl.setNetmask(in_addr_t *_netmask) {
		netmask = *_netmask;
	}

	command in_addr_t* IpControl.getIp() {
		return &myIp;
	}

	command in_addr_t* IpControl.getGateway() {
		return &gateway;
	}

	command in_addr_t* IpControl.getNetmask() {
		return &netmask;
	}

	command error_t PacketSender.send(ip_queue_item_t *item) {
		in_addr_t *dstIp;
		// create ip packet

		// todo: to init ???
		packet.header.version = 0x45;	// l-nibble: version=ipv4, h-nibble: IHL=ip header length as multiple of 4byte. 20byte when NO OPTIONS!
		packet.header.TOS = 0x00;		// type of service, no priority

		packet.header.identification = 0x6666;	// FIXME. konstante ok wenn keine framgmente erlaubt?
		packet.header.flags_fragOffset = 0x00;	// FIXME. siehe identification...
		packet.header.ttl = 0xFF;		// time to live
		// bis hier

		packet.header.len = item->dataLen + sizeof(ip_header_t);
		packet.header.dstIp = *(item->dstIp);
		packet.header.srcIp = myIp;
		memcpy(&(packet.data), item->data,  item->dataLen);
		packet.header.protocol = item->protocol;

		packet.header.chkSum = 0;
		packet.header.chkSum = header_checksum(&packet);

		if ((packet.header.srcIp.addr & netmask.addr) == (packet.header.dstIp.addr & netmask.addr)) {	// belongs to my subnet. send directly to host
			dstIp = &(packet.header.dstIp);
		}
		else {																			// belongs to other subnet. send packet to GATEWAY
			dstIp = &gateway;
		}

		return call Arp.resolve(dstIp);
	}

	default event void IpReceive.received[uint8_t protocol](in_addr_t *srcIp, uint8_t *data, uint16_t len) {
		// unknown protocol, drop packet
	}

	event void LlcReceive.received(mac_addr_t *srcMac, uint8_t *data) {
		ip_packet_t *p;

		p = (ip_packet_t*)data;
		currentReceivedPacket = p;

		// todo: check checksum

		if ((p->header.dstIp.addr == myIp.addr) ||
			( ((p->header.dstIp.addr & ~netmask.addr) == ~netmask.addr) &&
			  ((p->header.dstIp.addr & netmask.addr) == (myIp.addr & netmask.addr))
           )) {
			signal IpReceive.received[p->header.protocol](&(p->header.srcIp), (uint8_t*)&(p->data), p->header.len - sizeof(ip_header_t));
		}
	}

	event void LlcSend.sendDone(error_t error) {
		signal PacketSender.sendDone(error);
	}

	event void Arp.resolved(mac_addr_t *dstMac) {
		if (dstMac == NULL) {
			signal PacketSender.sendDone(FAIL);
		}
		else {
			call LlcSend.send(dstMac, (uint8_t*)&packet, packet.header.len);
		}
	}
}

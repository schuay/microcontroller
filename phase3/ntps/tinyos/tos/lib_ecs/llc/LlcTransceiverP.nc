/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

module LlcTransceiverP {
	provides interface PacketSender<mac_queue_item_t>;
	provides interface LlcReceive[uint16_t etherType];
	uses interface Mac;
	provides interface MacControl;
}

implementation {
	mac_packet_t packet;
	mac_addr_t broadcast = { .bytes {0xff, 0xff, 0xff, 0xff, 0xff, 0xff}};
	
	command mac_addr_t* MacControl.getMac() {
		return call Mac.getMac();
	}
	
	command error_t PacketSender.send(mac_queue_item_t *item) {
		// create mac packet
		
		packet.header.dstMac = item->dstMac;
		packet.header.srcMac = *(call MacControl.getMac());
		packet.header.etherType = item->etherType;
		memcpy(&(packet.data), item->data, item->dataLen);
		
		return call Mac.send(&(packet), item->dataLen + sizeof(mac_header_t));
	}
	
	default event void LlcReceive.received[uint16_t etherType](mac_addr_t *srcMac, uint8_t *data) {
		// unknown etherType, drop packet
	}
	
	event void Mac.received(mac_packet_t *p) {		
		//if ((memcmp(&(p->header.dstMac), call Mac.getMac(), sizeof(mac_addr_t)) == 0) || (memcmp(&(p->header.dstMac), &broadcast, sizeof(mac_addr_t)) == 0)) {
			signal LlcReceive.received[p->header.etherType](&(p->header.srcMac), (uint8_t*)&(p->data));
		//}
	}

	event void Mac.sendDone(error_t error) {
		signal PacketSender.sendDone(error);
	}
}

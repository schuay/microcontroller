/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"
#include <stdio.h>

module UdpQueueP {
	provides interface UdpQueue[uint8_t client];
	uses interface PacketQueue<udp_queue_item_t>;
}

implementation {
	default event void UdpQueue.sendDone[uint8_t client](error_t error) {
		// this should never happen
	}
		
	command error_t UdpQueue.send[uint8_t client](in_addr_t *dstIp, uint16_t srcPort, uint16_t dstPort, uint8_t *data, uint16_t len) {
		udp_queue_item_t *item;
		
		item = call PacketQueue.getBuffer(client);
		if (item == NULL) return EBUSY;
		
		item->data = data;
		item->dstIp = *dstIp;
		item->srcPort = srcPort;
		item->dstPort = dstPort;
		item->dataLen = len;
		
		call PacketQueue.send(client);
	
		return SUCCESS;
	}
	
	event void PacketQueue.sendDone(uint8_t index, error_t error) {
		signal UdpQueue.sendDone[index](error);
	}
}

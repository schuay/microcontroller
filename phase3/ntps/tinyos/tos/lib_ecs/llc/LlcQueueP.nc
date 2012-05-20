/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"
#include <stdio.h>

module LlcQueueP {
	provides interface LlcQueue[uint8_t client];
	uses interface PacketQueue<mac_queue_item_t>;
}

implementation {
	default event void LlcQueue.sendDone[uint8_t client](error_t error) {
		// this should never happen
	}
		
	command error_t LlcQueue.send[uint8_t client](mac_addr_t *dstMac, uint16_t etherType, uint8_t *data, uint16_t len) {
		mac_queue_item_t *item;
		
		item = call PacketQueue.getBuffer(client);
		if (item == NULL) return EBUSY;
		
		item->dstMac = *dstMac;
		item->etherType = etherType;
		item->data = data;
		item->dataLen = len;
		
		call PacketQueue.send(client);
	
		return SUCCESS;
	}
	
	event void PacketQueue.sendDone(uint8_t index, error_t error) {
		signal LlcQueue.sendDone[index](error);
	}
}

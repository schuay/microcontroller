/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"
#include <stdio.h>

module IcmpQueueP {
	provides interface IcmpQueue[uint8_t client];
	uses interface PacketQueue<icmp_queue_item_t>;
}

implementation {
	default event void IcmpQueue.sendDone[uint8_t client](error_t error) {
		// this should never happen
	}
		
	command error_t IcmpQueue.send[uint8_t client](in_addr_t *dstIp, uint8_t type, uint8_t code, uint8_t *data, uint16_t len) {
		icmp_queue_item_t *item;
		
		item = call PacketQueue.getBuffer(client);
		if (item == NULL) return EBUSY;
		
		item->data = data;
		item->dstIp = *dstIp;
		item->type = type;
		item->code = code;
		item->dataLen = len;
		
		call PacketQueue.send(client);
	
		return SUCCESS;
	}
	
	event void PacketQueue.sendDone(uint8_t index, error_t error) {
		signal IcmpQueue.sendDone[index](error);
	}
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"
#include <stdio.h>

module IpQueueP {
	provides interface IpQueue[uint8_t client];
	uses interface PacketQueue<ip_queue_item_t>;
}

implementation {
	default event void IpQueue.sendDone[uint8_t client](error_t error) {
		// this should never happen
	}
		
	command error_t IpQueue.send[uint8_t client](in_addr_t *dstIp, uint8_t protocol, uint8_t *data, uint16_t len) {
		ip_queue_item_t *item;
		
		item = call PacketQueue.getBuffer(client);
		if (item == NULL) return EBUSY;
		
		item->dstIp = dstIp;
		item->protocol = protocol;
		item->data = data;
		item->dataLen = len;
		
		call PacketQueue.send(client);
	
		return SUCCESS;
	}
	
	event void PacketQueue.sendDone(uint8_t index, error_t error) {
		signal IpQueue.sendDone[index](error);
	}
}

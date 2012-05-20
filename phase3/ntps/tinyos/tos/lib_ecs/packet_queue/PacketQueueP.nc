/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "packet_queue.h"
#include <stdio.h>

generic module PacketQueueP(typedef ITEM_TYPE , uint8_t QUEUE_LEN) {
	provides interface PacketQueue<ITEM_TYPE>;
	uses interface PacketSender<ITEM_TYPE>;
}

implementation {
	typedef struct {
		queue_item_state_t state;
		ITEM_TYPE item;
	} queue_item_t;
	
	queue_item_t queue[QUEUE_LEN];
	uint8_t currentIndex = 0;
	queue_state_t state = IDLE;
	
	task void sendNext() {
		uint8_t i;
		error_t error;
		
		if (state != IDLE) return;
		
		for (i=0; i<QUEUE_LEN; i++) {
			currentIndex = (currentIndex + 1) % QUEUE_LEN;
			if (queue[currentIndex].state == PENDING) {
				break;
			}
		}
		
		if (i == QUEUE_LEN) {	// queue is empty
			return;
		}
		
		error = call PacketSender.send(&(queue[currentIndex].item)); 
		if (error != SUCCESS) {
			queue[currentIndex].state = EMPTY;
			signal PacketQueue.sendDone(currentIndex, error);
		}
		else {
			state = SENDING;
		}
	}
	
	command ITEM_TYPE* PacketQueue.getBuffer(uint8_t index) {
		if (queue[index].state != EMPTY) return NULL;
		
		return &(queue[index].item);
	}
	
	command void PacketQueue.send(uint8_t client) {
		queue[client].state = PENDING;
		post sendNext();
	}
	
	event void PacketSender.sendDone(error_t error) {
		state = IDLE;
		
		queue[currentIndex].state = EMPTY;
		signal PacketQueue.sendDone(currentIndex, error);
		
		post sendNext();
	}
}

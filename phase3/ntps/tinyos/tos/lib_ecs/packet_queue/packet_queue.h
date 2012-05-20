/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef PACKET_QUEUE_H
#define PACKET_QUEUE_H

typedef enum {
	 EMPTY = 0,
	 PENDING,
} queue_item_state_t;

typedef enum {
	IDLE,
	SENDING,
} queue_state_t;

#endif

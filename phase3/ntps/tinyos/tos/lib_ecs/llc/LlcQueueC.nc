/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

configuration LlcQueueC {
	provides interface LlcQueue[uint8_t client];
}

implementation {
	components new PacketQueueC(mac_queue_item_t, uniqueCount(UQ_MAC));
	components LlcQueueP;
	components LlcTransceiverC;
	
	PacketQueueC.PacketSender -> LlcTransceiverC.PacketSender;
	LlcQueueP.LlcQueue = LlcQueue;
	LlcQueueP.PacketQueue -> PacketQueueC;
}

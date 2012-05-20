/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"

configuration UdpQueueC {
	provides interface UdpQueue[uint8_t client];
}

implementation {
	components UdpTransceiverC;
	components new PacketQueueC(udp_queue_item_t, uniqueCount(UQ_UDP));
	components UdpQueueP;
	
	UdpQueueP.UdpQueue = UdpQueue;
	UdpQueueP.PacketQueue -> PacketQueueC;
	PacketQueueC.PacketSender -> UdpTransceiverC.PacketSender;
}

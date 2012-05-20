/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"

configuration IcmpQueueC {
	provides interface IcmpQueue[uint8_t client];
}

implementation {
	components IcmpTransceiverC;
	components new PacketQueueC(icmp_queue_item_t, uniqueCount(UQ_ICMP));
	components IcmpQueueP;
	
	IcmpQueueP.IcmpQueue = IcmpQueue;
	IcmpQueueP.PacketQueue -> PacketQueueC;
	PacketQueueC.PacketSender -> IcmpTransceiverC.PacketSender;
}

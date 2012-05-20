/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ip.h"

configuration IpQueueC {
	provides interface IpQueue[uint8_t client];
}

implementation {
	components new PacketQueueC(ip_queue_item_t, uniqueCount(UQ_IP));
	components IpQueueP;
	components IpTransceiverC;
	
	IpQueueP.IpQueue = IpQueue;
	IpQueueP.PacketQueue -> PacketQueueC;
	PacketQueueC.PacketSender -> IpTransceiverC.PacketSender;
}

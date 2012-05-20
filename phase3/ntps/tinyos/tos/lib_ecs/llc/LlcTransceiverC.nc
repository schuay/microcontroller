/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

configuration LlcTransceiverC {
	provides interface PacketSender<mac_queue_item_t> @exactlyonce();
	provides interface LlcReceive[uint16_t etherType];
	uses interface Mac;
	provides interface MacControl;
}

implementation {
	components LlcTransceiverP;

	LlcTransceiverP.PacketSender = PacketSender;
	LlcTransceiverP.LlcReceive = LlcReceive;
	LlcTransceiverP.Mac = Mac;
	LlcTransceiverP.MacControl = MacControl;
}

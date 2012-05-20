/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

generic configuration LlcC(uint16_t ETHER_TYPE) {
	provides interface LlcSend;
	provides interface LlcReceive;
}

implementation {
	components LlcTransceiverC;
	components new LlcP(ETHER_TYPE);
	components LlcQueueC;
	
	LlcP.LlcSend = LlcSend;
	LlcP.LlcQueue -> LlcQueueC.LlcQueue[unique(UQ_MAC)];
				
	LlcTransceiverC.LlcReceive[ETHER_TYPE] = LlcReceive;
}

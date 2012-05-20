/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"

generic configuration UdpC(uint16_t PORT) {
	provides interface UdpSend;
	provides interface UdpReceive;
}

implementation {
	components UdpTransceiverC;
	components new UdpP(PORT);
	components UdpQueueC;
	
	UdpP.UdpSend = UdpSend;
	UdpP.UdpQueue -> UdpQueueC.UdpQueue[unique(UQ_UDP)];
	UdpTransceiverC.UdpReceive[PORT] = UdpReceive;
}

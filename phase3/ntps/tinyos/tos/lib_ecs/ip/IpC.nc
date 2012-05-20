/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ip.h"

generic configuration IpC(uint16_t PROTOCOL) {
	provides interface IpSend;
	provides interface IpReceive;
}

implementation {
	components IpTransceiverC;
	components new IpP(PROTOCOL);
	components IpQueueC;
	
	IpP.IpSend = IpSend;
	IpP.IpQueue -> IpQueueC.IpQueue[unique(UQ_IP)];
	IpTransceiverC.IpReceive[PROTOCOL] = IpReceive;
}

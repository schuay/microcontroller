/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"

generic configuration IcmpC(uint8_t TYPE) {
	provides interface IcmpSend;
	provides interface IcmpReceive;
}

implementation {
	components IcmpTransceiverC;
	components new IcmpP(TYPE);
	components IcmpQueueC;
	
	IcmpP.IcmpSend = IcmpSend;
	IcmpP.IcmpQueue -> IcmpQueueC.IcmpQueue[unique(UQ_ICMP)];
	IcmpTransceiverC.IcmpReceive[TYPE] = IcmpReceive;
}

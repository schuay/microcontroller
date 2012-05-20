/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "udp.h"

generic module UdpP(uint16_t PORT) {
	provides interface UdpSend;
	uses interface UdpQueue;
}

implementation {
	command error_t UdpSend.send(in_addr_t *dstIp, uint16_t dstPort, uint8_t *data, uint16_t len) {
		return call UdpQueue.send(dstIp, PORT, dstPort, data, len);
	}
	
	event void UdpQueue.sendDone(error_t error) {
		signal UdpSend.sendDone(error);
	}
}

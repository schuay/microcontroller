/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

generic module LlcP(uint16_t ETHER_TYPE) {
	provides interface LlcSend;
	uses interface LlcQueue;
}

implementation {
	command error_t LlcSend.send(mac_addr_t *dstMac, uint8_t *data, uint16_t len) {
		return call LlcQueue.send(dstMac, ETHER_TYPE, data, len);
	}
	
	event void LlcQueue.sendDone(error_t error) {
		signal LlcSend.sendDone(error);
	}
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "icmp.h"

generic module IcmpP(uint8_t TYPE) {
	provides interface IcmpSend;
	uses interface IcmpQueue;
}

implementation {
	command error_t IcmpSend.send(in_addr_t *dstIp, uint8_t type, uint8_t code, uint8_t *data, uint16_t len) {
		return call IcmpQueue.send(dstIp, type, code, data, len);
	}
	
	event void IcmpQueue.sendDone(error_t error) {
		signal IcmpSend.sendDone(error);
	}
}

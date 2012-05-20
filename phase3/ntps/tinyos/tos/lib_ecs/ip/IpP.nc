/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "ip.h"

generic module IpP(uint16_t PROTOCOL) {
	provides interface IpSend;
	uses interface IpQueue;
}

implementation {
	command error_t IpSend.send(in_addr_t *dstIp, uint8_t *data, uint16_t len) {
		return call IpQueue.send(dstIp, PROTOCOL, data, len);
	}
	
	event void IpQueue.sendDone(error_t error) {
		signal IpSend.sendDone(error);
	}
}

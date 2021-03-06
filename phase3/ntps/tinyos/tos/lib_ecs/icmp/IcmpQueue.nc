/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface IcmpQueue {
	command error_t send(in_addr_t *dstIp, uint8_t type, uint8_t code, uint8_t *data, uint16_t len);
	event void sendDone(error_t error);
}

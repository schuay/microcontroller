/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface LlcQueue {
	command error_t send(mac_addr_t *dstMac, uint16_t etherType, uint8_t *data, uint16_t len);
	event void sendDone(error_t error);
}

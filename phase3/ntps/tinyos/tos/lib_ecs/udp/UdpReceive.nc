/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface UdpReceive {
	event void received(in_addr_t *srcIp, uint16_t srcPort, uint8_t *data, uint16_t len);
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface PacketQueue<item_type> {
	command item_type* getBuffer(uint8_t index);
	command void send(uint8_t index);
	event void sendDone(uint8_t index, error_t error);
}

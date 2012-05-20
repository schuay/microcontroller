/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface PacketSender<item_type_t> {
	command error_t send(item_type_t *item);
	event void sendDone(error_t error);
}
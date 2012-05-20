/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

generic configuration PacketQueueC(typedef ITEM_TYPE, uint8_t LEN) {
	provides interface PacketQueue<ITEM_TYPE>;
	uses interface PacketSender<ITEM_TYPE> @exactlyonce();
}

implementation {
	components new PacketQueueP(ITEM_TYPE, LEN);
	
	PacketQueueP.PacketSender = PacketSender;
	PacketQueueP.PacketQueue = PacketQueue;
}
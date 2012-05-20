/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

module PingP {
	uses interface IcmpReceive;
	uses interface IcmpSend;
}

implementation {
	uint8_t pingData[100];
	
	event void IcmpReceive.received(in_addr_t *srcIp, uint8_t code, uint8_t *data, uint16_t len) {
		/* Send reply to ICMP echo recqest here*/






	}
	
	event void IcmpSend.sendDone(error_t error) {
	
	}
}

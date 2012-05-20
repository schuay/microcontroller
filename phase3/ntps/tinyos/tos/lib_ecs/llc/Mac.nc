/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "mac.h"

interface Mac {
	command error_t send(mac_packet_t *data, uint16_t len);
	event void sendDone(error_t error);
	event void received(mac_packet_t *data);
	command mac_addr_t* getMac();
}

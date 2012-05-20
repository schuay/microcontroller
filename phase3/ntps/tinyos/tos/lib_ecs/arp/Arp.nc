/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "arp.h"

interface Arp {
	command error_t resolve(in_addr_t *ip);
	event void resolved(mac_addr_t *macPtr);
}


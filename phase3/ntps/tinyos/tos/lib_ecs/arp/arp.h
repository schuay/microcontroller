/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef ARP_H
#define ARP_H

#include "ip.h"
#include "mac.h"

enum {
	CACHESIZE	= 4,
	ARP_TIMEOUT	= 100,
	ARP_CLEAR_CACHE_INTERVAL = 30000,
	ARP_RETRIES	= 3,
	ETHER_TYPE_ARP = 0x0806,
	REQUEST_QUEUE = 0,
	REPLY_QUEUE = 1,
};

enum {
	ARP_REQUEST	= 0x01,
	ARP_REPLY	= 0x02,
};

typedef enum {
	ARP_IDLE = 0,
	ARP_WAITING,
} arp_state_t;

typedef struct {
	nx_uint16_t hwType;
	nx_uint16_t prot;
	nx_uint8_t hwSize;
	nx_uint8_t protSize;
	nx_uint16_t operation;
	mac_addr_t srcMac;
	in_addr_t srcIp;
	mac_addr_t dstMac;
	in_addr_t dstIp;
} arp_packet_t;

typedef struct {
	in_addr_t ip;
	mac_addr_t mac;
} arp_cache_entry_t;

#endif

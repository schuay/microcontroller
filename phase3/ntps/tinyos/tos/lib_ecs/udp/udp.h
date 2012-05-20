/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef UDP_H
#define UDP_H

#include "ip.h"

#define UQ_UDP "unique_udp"


enum {
	UDP_MAX_PACKET_LEN = 100,
	IP_PROTOCOL_UDP	= 0x11,
};

typedef struct{
	nx_uint16_t srcPort;
	nx_uint16_t dstPort;
	nx_uint16_t len;
	nx_uint16_t chkSum;
} udp_header_t;

typedef struct {
	udp_header_t header;
	uint8_t data[UDP_MAX_PACKET_LEN];
} udp_packet_t;

typedef struct {
	in_addr_t dstIp;
	uint16_t srcPort;
	uint16_t dstPort;
	uint8_t *data;
	uint16_t dataLen;
} udp_queue_item_t;

#endif

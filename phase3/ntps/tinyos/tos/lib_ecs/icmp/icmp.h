/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef ICMP_H
#define ICMP_H

#define UQ_ICMP "unique_icmp"

enum {
	ICMP_MAX_PACKET_LEN = 150,
	IP_PROTOCOL_ICMP	= 0x1,
};

typedef struct {
	nx_uint8_t type;
	nx_uint8_t code;
	uint16_t checksum;
} icmp_header_t;

typedef struct {
	icmp_header_t header;
	uint8_t data[ICMP_MAX_PACKET_LEN];
} icmp_packet_t;

typedef struct {
	in_addr_t dstIp;
	uint8_t type;
	uint8_t code;
	uint8_t *data;
	uint16_t dataLen;
} icmp_queue_item_t;

#endif

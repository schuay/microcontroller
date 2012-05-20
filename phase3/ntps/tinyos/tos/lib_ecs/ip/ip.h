/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef IP_H
#define IP_H

#define UQ_IP "unique_ip"

enum {
	ETHER_TYPE_IPV4	= 0x0800,
	MAX_IP_PACKET_LEN = 200,
};

typedef union {
	struct {
		uint8_t b1;
		uint8_t b2;
		uint8_t b3;
		uint8_t b4;
	} bytes;
	uint32_t addr;		// for comparison
} in_addr_t;

/*
	ATTENTION: NO Fragmentation and NO ip-options supported. so the ip-header is alwas 20byte long
	and the idendtification and flags/frag-offset - fields are set to constants...
*/
typedef struct {
	nx_uint8_t version;
	nx_uint8_t TOS;
	nx_uint16_t len;
	nx_uint16_t identification;
	nx_uint16_t flags_fragOffset;
	nx_uint8_t ttl;
	nx_uint8_t protocol;
	uint16_t chkSum;
	in_addr_t srcIp;
	in_addr_t dstIp;
} ip_header_t;

typedef struct {
	ip_header_t header;
	uint8_t data[MAX_IP_PACKET_LEN];
} ip_packet_t;

typedef struct {
	in_addr_t *dstIp;
	uint8_t protocol;
	uint8_t *data;
	uint16_t dataLen;
} ip_queue_item_t;

#endif

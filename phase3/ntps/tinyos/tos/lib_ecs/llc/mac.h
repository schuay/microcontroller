/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#ifndef MAC_H
#define MAC_H

#define UQ_MAC "unique_mac"

enum {
	MAC_MAX_PACKET_LEN = 200,
};

typedef union {
	struct {
		uint8_t b1;
		uint8_t b2;
		uint8_t b3;
		uint8_t b4;
		uint8_t b5;
		uint8_t b6;
        } bytes;
} mac_addr_t;

typedef struct {
	mac_addr_t dstMac;
	mac_addr_t srcMac;
	nx_uint16_t etherType;
} mac_header_t;

typedef struct {
	mac_header_t header;
	uint8_t data[MAC_MAX_PACKET_LEN];
} mac_packet_t;

typedef struct {
	mac_addr_t dstMac;
	uint16_t etherType;
	uint8_t *data;
	uint16_t dataLen;
} mac_queue_item_t;

#endif

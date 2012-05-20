/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "arp.h"
#include "udp.h"

module ArpP {
	provides interface Arp;
	provides interface PacketSender<arp_packet_t>;
	uses interface PacketQueue<arp_packet_t>;
	uses interface Timer<TMilli> as Timeout;
	uses interface Timer<TMilli> as ClearCacheTimeout;
	uses interface LlcSend;
	uses interface LlcReceive;
	uses interface IpControl;
	uses interface MacControl;
	provides interface Init;
}

implementation {
	arp_cache_entry_t cache[CACHESIZE];
	uint8_t cacheReadP = 0, cacheWriteP = 0;
	uint8_t retries = 0;
	arp_state_t state = ARP_IDLE;
	in_addr_t ipToResolve;
		
	mac_addr_t* getFromCache(in_addr_t *ip) {
		uint8_t count;

		for(count = 0; count < CACHESIZE; count++) {
			if(cache[cacheReadP].ip.addr == ip->addr) {
				return &(cache[cacheReadP].mac);
			}
			//POSTinc / assumption: most of the time, packets will go to same MAC, so readPtr points to right MAC/IP immedeatly
			cacheReadP = (cacheReadP + 1) % CACHESIZE;
		}
		
		return NULL;
	}
	
	error_t send_packet(uint8_t operation, mac_addr_t *dstMac, in_addr_t *dstIp) {
		arp_packet_t *packet;
		uint8_t client;
		
		client = operation - 1;
					
		packet = call PacketQueue.getBuffer(client);
		if (packet == NULL) return EBUSY;
					
		packet->hwType = 1;
		packet->prot = 0x0800;
		packet->hwSize = 6;
		packet->protSize = 4;
		packet->srcIp = *(call IpControl.getIp());
		packet->srcMac = *(call MacControl.getMac());
		packet->dstMac = *dstMac;
		packet->dstIp = *dstIp;
		packet->operation = operation;
		
		call PacketQueue.send(client);
		
		return SUCCESS;
	}

	command error_t Init.init() {
		call ClearCacheTimeout.startPeriodic(ARP_CLEAR_CACHE_INTERVAL);
		return SUCCESS;
	}

	event void ClearCacheTimeout.fired() {
		uint8_t count;

		for(count = 0; count < CACHESIZE; count++) {
			cache[count].ip.addr = 0;
		}
	}

	event void LlcReceive.received(mac_addr_t *srcAddr, uint8_t *data) {
		arp_packet_t *packet;
		
		packet = (arp_packet_t*)data;
		
		switch (packet->operation) {
			case ARP_REQUEST:
				if ((call IpControl.getIp())->addr == packet->dstIp.addr) {
					send_packet(ARP_REPLY, &(packet->srcMac), &(packet->srcIp));
				}
				break;
			case ARP_REPLY:
				if (state == ARP_WAITING) {
					// write to cache
					cache[cacheWriteP].ip = packet->srcIp;
					cache[cacheWriteP].mac = packet->srcMac;
					
					call Timeout.stop();
					state = ARP_IDLE;
					signal Arp.resolved(&(cache[cacheWriteP].mac));
					
					cacheWriteP = (cacheWriteP + 1) % CACHESIZE;
				}
				break;
		}
	}

	void sendRequest() {
		static mac_addr_t dstMac = { .bytes {0xff, 0xff, 0xff, 0xff, 0xff, 0xff}};

		state = ARP_WAITING;
		send_packet(ARP_REQUEST, &(dstMac), &ipToResolve);
			
		call Timeout.startOneShot(ARP_TIMEOUT);
	}

	command error_t Arp.resolve(in_addr_t *ip) {
		static mac_addr_t broadcastMac = { .bytes {0xff, 0xff, 0xff, 0xff, 0xff, 0xff}};
		static mac_addr_t *macAddr;
		in_addr_t *netmask;

		netmask = call IpControl.getNetmask();
		
		if ((ip->addr & ~(netmask->addr)) == ~(netmask->addr)) {	// broadcast address ?
			signal Arp.resolved(&broadcastMac);
		}
		else {
			macAddr = getFromCache(ip);
			if (macAddr != NULL) {
				signal Arp.resolved(macAddr);
			}
			else {
				if (state != ARP_IDLE) {
					return EBUSY;
				}
			
				ipToResolve = *ip;
				retries = 0;
				sendRequest();
			}
		}
		
		return SUCCESS;
	}
	
	event void Timeout.fired() {
		state = ARP_IDLE;

		retries++;
		if (retries < ARP_RETRIES) {
			sendRequest();
		}
		else {
			signal Arp.resolved(NULL);
		}
	}
	
	event void LlcSend.sendDone(error_t error) {
		signal PacketSender.sendDone(error);
	}
	
	command error_t PacketSender.send(arp_packet_t *item) {
		return call LlcSend.send(&(item->dstMac), (uint8_t*)item, sizeof(arp_packet_t));
	}
	
	event void PacketQueue.sendDone(uint8_t index, error_t error) {
		if ((index+1 == ARP_REQUEST) && (error != SUCCESS) && (state == ARP_WAITING)) {
			state = ARP_IDLE;
			call Timeout.stop();
			signal Arp.resolved(NULL);
		}
	}
}

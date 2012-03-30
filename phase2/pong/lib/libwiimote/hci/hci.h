#ifndef HCI_H
#define HCI_H

#include <stdint.h>
#include <util.h>

#define CONNECTION_STATUS_T

typedef enum {
	DISCONNECTED,
	CONNECTED,
} connection_status_t;

error_t hci_init(void);

error_t hci_create_connection(uint8_t wii, const uint8_t address[]);

extern void hci_connection_complete(uint8_t wii, connection_status_t status);
extern void hci_disconnection_complete(uint8_t wii);

error_t hci_transmit(uint8_t wii, uint8_t length, const uint8_t data[]);

extern void hci_number_of_completed_packets(uint8_t wii);
extern void hci_receive(uint8_t connection, uint8_t length, const uint8_t data[]);

#endif

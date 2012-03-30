#ifndef WII_USER
#define WII_USER

#include <stdint.h>
#include <util.h>
#include <wii_bt.h>

#ifndef WII
#define WII 4
#endif

#ifndef CONNECTION_STATUS_T
typedef enum {
	DISCONNECTED,
	CONNECTED,
} connection_status_t;
#endif

error_t wiiUserInit(void (*rcvButton)(uint8_t, uint16_t), void (*rcvAccel)(uint8_t wii, uint16_t x, uint16_t y, uint16_t z));
error_t wiiUserConnect(uint8_t wii, const uint8_t *mac, void (*conCallback)(uint8_t wii, connection_status_t status));
error_t wiiUserSetLeds(uint8_t wii, uint8_t bitmask, void (*setLedsCallback)(uint8_t wii, error_t status));
error_t wiiUserSetAccel(uint8_t wii, uint8_t enable, void (*setAccelCallback)(uint8_t wii, error_t status));
error_t wiiUserSetRumbler(uint8_t wii, uint8_t enable, void (*setRumblerCallback)(uint8_t wii, error_t status));

#endif

#ifndef WII_BT
#define WII_BT

#include <stdint.h>
#include <util.h>
#include "hci.h"

#ifndef WII
#define WII 4
#endif

error_t wiiBtInit(void (*sndCallback)(uint8_t wii), void (*rcvCallback)(uint8_t wii, uint8_t length, const uint8_t data[]));
error_t wiiBtConnect(uint8_t wii, const uint8_t mac[], void (*conCallback)(uint8_t wii, connection_status_t status));
error_t wiiBtSendRaw(uint8_t wii, uint8_t length, const uint8_t data[]);

#endif

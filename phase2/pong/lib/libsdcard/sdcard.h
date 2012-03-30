#ifndef SDCARD_H
#define SDCARD_H

#include <avr/io.h>
#include "util.h"
#include <stdbool.h>

#define SDCARD_PORT	PORTG
#define SDCARD_DDR	DDRG
#define SDCARD_PIN	PING

#define SDCARD_CS	PG1
#define SDCARD_CD	PG2

extern void spiSend(uint8_t data);
extern uint8_t spiReceive(void);

typedef uint8_t sdcard_block_t[32];

extern bool sdcardAvailable(void);
extern error_t sdcardInit(void);
extern error_t sdcardReadBlock(uint32_t blockAddress, sdcard_block_t buffer);

#endif


#include "sdcard.h"
#include <stdlib.h>
#include <avr/pgmspace.h>

#ifdef DEBUG
#include "printf.h"
#define debug(...) printf(__VA_ARGS__)
#else
#define debug(...) do{}while(0);
#endif


#define READ_TIMEOUT	1000000UL
#define COMMAND_LEN	6

static inline error_t waitOnNot(uint8_t value);
static error_t command(const uint8_t *, uint8_t *ret);
static inline void csEnable(void);
static inline void csDisable(void);

void csEnable() {
	SDCARD_PORT &= ~((1<<SDCARD_CS));
}

void csDisable() {
	SDCARD_PORT |= ((1<<SDCARD_CS));
}

error_t sdcardInit() {
	uint8_t i;
	uint8_t byte;
	error_t err;
	uint32_t timeout;

	const uint8_t reset[] 			= {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
	const uint8_t app[]				= {0x77, 0x00, 0x00, 0x00, 0x00, 0xFF};	// CMD55
	const uint8_t sendOpCond[]		= {0x69, 0x00, 0x00, 0x00, 0x00, 0xFF};	// ACMD41
	const uint8_t setBlocklen[]		= {0x50, 0x00, 0x00, 0x00, 0x20, 0xFF};	// CMD16

	SDCARD_DDR = (SDCARD_DDR & ~(1<<SDCARD_CD)) | (1<<SDCARD_CS);
	SDCARD_PORT |= (1<<SDCARD_CS);

	csEnable();

	// sending dummy-packets
	for (i = 0; i<200; i++) {
		spiSend(0xFF);
	}

	err = command(reset, &byte);
	if (err != SUCCESS) {
		debug("reset failed\n");
		goto error;
	}

	timeout = READ_TIMEOUT;
	do {
		err = command(app, &byte);
		if (err != SUCCESS) {
			debug("app failed\n");
			goto error;
		}
		err = command(sendOpCond, &byte);
		if (err != SUCCESS) {
			debug("sendOpCond failed\n");
			goto error;
		}
		timeout--;
	} while (byte != 0 && timeout > 0);

	if (timeout == 0) {
		debug("init failed\n");
		err = E_TIMEOUT;
		goto error;
	}

	err = command(setBlocklen, &byte);
	if (err != SUCCESS) {
		debug("setBlocklen failed\n");
	}

error:
	csDisable();
	return err;
}

bool sdcardAvailable() {
	return ((SDCARD_PIN & SDCARD_CD) == 0) ? false : true;
}

error_t sdcardReadBlock(uint32_t blockAddress, sdcard_block_t buffer) {
	uint8_t i;
	uint8_t byte;
	error_t err;

	static uint8_t read[]	= {0x51, 0x00, 0x00, 0x00, 0x00, 0xFF};	// CMD17

	csEnable();

	// send address
	blockAddress <<= 5;
	read[1] = (blockAddress >> 24);
	read[2] = (blockAddress >> 16);
	read[3] = (blockAddress >> 8);
	read[4] = blockAddress;

	err = command(read, &byte);
	if (err != SUCCESS) {
		debug("read failed\n");
		goto error;
	}

	err = waitOnNot(254);
	if (err != SUCCESS) {
		debug("wait on data failed\n");
		goto error;
	}

	for (i=0; i<sizeof(sdcard_block_t); i++) {
		buffer[i] = spiReceive();
	}

error:
	csDisable();
	return err;
}

error_t waitOnNot(uint8_t value) {
	uint32_t timeout;
	uint8_t byte;

	timeout = READ_TIMEOUT;
	do {
		byte = spiReceive();
		timeout--;
	} while ((byte != value) && (timeout > 0));

	if (timeout == 0) {
		return E_TIMEOUT;
	}

	return SUCCESS;
}

error_t command(const uint8_t *command, uint8_t *ret) {
	uint8_t i;
	uint8_t byte;
	uint32_t timeout;

	for(i=0; i<COMMAND_LEN; i++) {
		spiSend(command[i]);
	}

	timeout = READ_TIMEOUT;
	do {
		byte = spiReceive();
		timeout--;
	} while ((byte == 255) && (timeout > 0));

	if (timeout == 0) {
		return E_TIMEOUT;
	}

	*ret = byte;

	return SUCCESS;
}


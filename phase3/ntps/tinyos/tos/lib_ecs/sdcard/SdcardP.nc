/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.03.2012
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

#include "sdcard.h"

module SdcardP {
	uses interface SpiByte;
	uses interface Resource;
	uses interface GeneralIO as cs;
	uses interface GeneralIO as cd;
	provides interface Sdcard;
}

implementation {

	enum {
		READ_TIMEOUT 	= 1000000UL,
		COMMAND_LEN		= 6,
	};

	typedef enum {
		SDC_UNINIT,
		SDC_INIT,
		SDC_IDLE,
		SDC_BUSY,
	} state_t;

	state_t state = SDC_UNINIT;

	uint32_t blockAddr;
	uint8_t *buffer;

	inline error_t waitOnNot(uint8_t value);
	error_t writeCommand(const uint8_t *com, uint8_t *ret);
	void sdcardInit();
	void sdcardReadBlock();

	command error_t Sdcard.init() {
		if (state != SDC_UNINIT) {
			return EALREADY;
		}

		call cs.makeOutput();
		call cd.makeInput();

		call cs.set();

		DDRB |= (1<<PB0);		// todo: why do we need this? put something like this into the spi module
		state = SDC_INIT;

		return call Resource.request();
	}

	command error_t Sdcard.readBlock(uint32_t a, uint8_t *b) {
		if (state != SDC_IDLE) {
			return EBUSY;
		}

		blockAddr = a;
		buffer = b;
		state = SDC_BUSY;

		return call Resource.request();
	}

	event void Resource.granted(void) {
		switch (state) {
		case SDC_INIT:
			sdcardInit();
			break;
		case SDC_BUSY:
			sdcardReadBlock();
			break;
		default:
			break;
		}
	}

	void sdcardInit() {
		uint8_t i;
		uint8_t byte;
		error_t err;
		uint32_t timeout;

		const uint8_t reset[] 			= {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};
		const uint8_t app[]				= {0x77, 0x00, 0x00, 0x00, 0x00, 0xFF};	// CMD55
		const uint8_t sendOpCond[]		= {0x69, 0x00, 0x00, 0x00, 0x00, 0xFF};	// ACMD41
		const uint8_t setBlocklen[]		= {0x50, 0x00, 0x00, 0x00, SDCARD_BLOCKSIZE, 0xFF};	// CMD16

		call cs.clr();

		debug("start init");

		// sending dummy-packets
		for (i = 0; i<200; i++) {
			call SpiByte.write(0xFF);
		}

		err = writeCommand(reset, &byte);
		if (err != SUCCESS) {
			debug("reset failed");
			goto error;
		}

		timeout = READ_TIMEOUT;
		do {
			err = writeCommand(app, &byte);
			if (err != SUCCESS) {
				debug("app failed");
				goto error;
			}
			err = writeCommand(sendOpCond, &byte);
			if (err != SUCCESS) {
				debug("sendOpCond failed");
				goto error;
			}
			timeout--;
		} while (byte != 0 && timeout > 0);

		if (timeout == 0) {
			debug("init failed");
			err = ERETRY;
			goto error;
		}

		err = writeCommand(setBlocklen, &byte);
		if (err != SUCCESS) {
			debug("setBlocklen failed");
		}

		state = SDC_IDLE;

error:
		call cs.set();
		call Resource.release();
		signal Sdcard.initDone(err);
	}

	command bool Sdcard.inserted() {
		return !call cd.get();
	}


	void sdcardReadBlock() {
		uint8_t i;
		uint8_t byte;
		error_t err;

		static uint8_t read[]	= {0x51, 0x00, 0x00, 0x00, 0x00, 0xFF};	// CMD17

		call cs.clr();

		debug("start read");

		// send address
		blockAddr <<= 5;
		read[1] = (blockAddr >> 24);
		read[2] = (blockAddr >> 16);
		read[3] = (blockAddr >> 8);
		read[4] = blockAddr;

		err = writeCommand(read, &byte);
		if (err != SUCCESS) {
			debug("read failed\n");
			goto error;
		}

		err = waitOnNot(254);
		if (err != SUCCESS) {
			debug("wait on data failed\n");
			goto error;
		}

		for (i=0; i<SDCARD_BLOCKSIZE; i++) {
			buffer[i] = call SpiByte.write(0xff);
		}

		state = SDC_IDLE;

	error:
		call cs.set();
		call Resource.release();
		signal Sdcard.readBlockDone(buffer, err);
	}

	error_t waitOnNot(uint8_t value) {
		uint32_t timeout;
		uint8_t byte;

		timeout = READ_TIMEOUT;
		do {
			byte = call SpiByte.write(0xff);
			timeout--;
		} while ((byte != value) && (timeout > 0));

		if (timeout == 0) {
			return ERETRY;
		}

		return SUCCESS;
	}

	error_t writeCommand(const uint8_t *com, uint8_t *ret) {
		uint8_t i;
		uint8_t byte;
		uint32_t timeout;

		for (i=0; i<COMMAND_LEN; i++) {
			call SpiByte.write(com[i]);
		}

		timeout = READ_TIMEOUT;
		do {
			byte = call SpiByte.write(0xff);
			timeout--;
		} while ((byte == 255) && (timeout > 0));

		if (timeout == 0) {
			return ERETRY;
		}

		*ret = byte;

		return SUCCESS;
	}
}


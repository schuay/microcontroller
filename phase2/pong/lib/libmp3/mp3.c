#include "mp3.h"

#include <util/delay.h>
#include <avr/interrupt.h>

// internal definitions
#define mp3CSLow()	MP3_PORT &= ~(1<<MP3_CS)
#define mp3CSHigh()	MP3_PORT |= (1<<MP3_CS)
#define bsyncLow()	MP3_PORT &= ~(1<<BSYNC)
#define bsyncHigh()	MP3_PORT |= (1<<BSYNC)
#define clearINT0Flag()	GIFR = (1<<INTF0)

static uint16_t sciRead(uint8_t addr);
static void sciWrite(uint8_t addr, uint16_t data);
static void mp3WaitBusy(void);
static void (*dataRequest)(void);

typedef enum {
	OP_WRITE= 0x02,
	OP_READ	= 0x03,
} opcode_t;

typedef enum {
	CLOCKF	= 0x03,
	MODE	= 0x00,
	VOL		= 0x0b,
} register_t;

bool mp3Busy() {
	if ((INT_PIN & (1<<DREQ)) == 0) {
		return true;
	}
	return false;
}

void mp3WaitBusy() {
	while (mp3Busy() == true);
}

void sciWrite(uint8_t addr, uint16_t data) {
	mp3WaitBusy();

	mp3CSLow();
	spiSend(OP_WRITE);
	spiSend(addr);
	spiSend((uint8_t)((data>>8) & 0xff));
	spiSend((uint8_t)((data>>0) & 0xff));
	mp3CSHigh();
}

uint16_t sciRead(uint8_t addr) {
	uint16_t value;

	mp3WaitBusy();

	mp3CSLow();
	spiSend(OP_READ);
	spiSend(addr);
	value = spiReceive() << 8;
	value |= spiReceive();
	mp3CSHigh();

	return value;
}

void mp3Init(void (*dataRequestCallback)(void)) {
	dataRequest = dataRequestCallback;

	// init ports
	MP3_DDR |= (1<<MP3_CS) | (1<<MP3_RST) | (1<<BSYNC);
	INT_PORT |= 1<<DREQ;
	INT_DDR &= ~(1<<DREQ);

	bsyncHigh();
	mp3CSHigh();

	// hardware reset
	MP3_PORT &= ~(1<<MP3_RST);
	_delay_ms(1);
	MP3_PORT |= (1<<MP3_RST);

	sciWrite(CLOCKF, 12500);	// set clock frequency
	sciWrite(MODE, (1<<11));	// native mode

	sciWrite(VOL, 0x3000);

	// init external INT0
	EICRA |= (1<<ISC01) | (1<<ISC00);
	EIMSK |= (1<<INT0);
}

void mp3SetVolume(uint8_t vol) {
	uint8_t temp;

	temp = 0xff - vol;

	mp3WaitBusy();
	sciWrite(VOL, temp | (temp<<8));
}

void mp3StartSineTest() {
	sciWrite(MODE, (1<<11)|(1<<5));

	mp3WaitBusy();

	bsyncLow();
	spiSend(0x53);
	spiSend(0xef);
	spiSend(0x6e);
	spiSend(0xcc);
	spiSend(0x00);
	spiSend(0x00);
	spiSend(0x00);
	spiSend(0x00);
	bsyncHigh();
}

void mp3SendMusic(uint8_t *buffer) {
	uint8_t i;

	mp3WaitBusy();		// during normal operation, this is no busy wait loop, only during initialisation

	bsyncLow();
	for (i=0; i<32; i++) {
		spiSend(buffer[i]);
	}
	bsyncHigh();
}

ISR (INT0_vect) {
	if (dataRequest != NULL) {
		dataRequest();
	}
}


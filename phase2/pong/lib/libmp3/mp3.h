#ifndef MP3_H
#define MP3_H

#include <avr/io.h>
#include <stdlib.h>
#include <stdbool.h>

// pins
#define MP3_PORT	PORTB
#define MP3_DDR		DDRB

#define MP3_CS		PB0
#define MP3_RST		PB4
#define BSYNC		PB5

#define INT_PORT	PORTD
#define	INT_DDR		DDRD
#define	INT_PIN		PIND

#define DREQ		PD0

extern void spiSend(uint8_t data);
extern uint8_t spiReceive(void);

extern void mp3Init(void (*dataRequestCallback)(void));
extern void mp3SetVolume(uint8_t volume);
extern void mp3SendMusic(uint8_t *buffer);
extern void mp3StartSineTest(void);
extern bool mp3Busy(void);

#endif

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	27.02.2012
 */

#include "KS0108.h"
#include "Standard5x7.h"

module GlcdTextP {
	provides interface GlcdText;
	provides interface Init;
	uses interface HplKS0108 as Hpl;
}

implementation {
	void lcdSetAddr(uint8_t x, uint8_t y);
	void lcdWrite(uint8_t data);
	void setStartLine(uint8_t line);
	uint8_t currentLine(void);
	void gotoLine(uint8_t l);
	void lcdClear(void);
	void write(uint8_t byte, uint8_t cs, bool rs);
	void setYAddr(uint8_t addr, uint8_t cs);
	void setXAddr(uint8_t addr, uint8_t cs);
	void clearLine(void);

	const font *f = &Standard5x7;

	uint8_t x = 0, y = 0;
	uint8_t line = 0;
	bool scroll = FALSE;

	command error_t Init.init() {
		call Hpl.init();

		call Hpl.controlWrite(1, 0x3f);	// display on
		call Hpl.controlWrite(0, 0x3f);	// display on
		call Hpl.controlWrite(1, 0xC0);	// start at line 0
		call Hpl.controlWrite(0, 0xC0);	// start at line 0
		lcdSetAddr(0, 0);

		lcdClear();

		return SUCCESS;
	}

	void setXAddr(uint8_t addr, uint8_t cs) {
		if (addr > 7) return;

		call Hpl.controlWrite(cs, 0xB8 | addr);
	}

	void setYAddr(uint8_t addr, uint8_t cs) {
		if (addr > 63) return;

		call Hpl.controlWrite(cs, 0x40 | addr);
	}

	void switchToNextLine() {
		y = 0;
		if (currentLine() == 7) {
			line = (line + 8) % 64;
			setStartLine(line);
		}
		x++;
		if (x > 7) {	// restart at line 0
			x = 0;
		}
		lcdSetAddr(x, 0);
	}

	void lcdWrite(uint8_t data) {
		if (y > 63) {
			call Hpl.dataWrite(0, data);
			y++;
		}
		else {
			call Hpl.dataWrite(1, data);
			y++;
		}
	}

	void lcdSetAddr(uint8_t xAddr, uint8_t yAddr) {
		x = xAddr;
		y = yAddr;

		if (yAddr > 63) {
			yAddr -= 64;
			setYAddr(yAddr, 0);
			setYAddr(0, 1);
		}
		else {
			setYAddr(yAddr, 1);
			setYAddr(0, 0);
		}
		setXAddr(xAddr, 0);
		setXAddr(xAddr, 1);
	}

	command void GlcdText.writeChar(char c) {
		uint8_t cv;
		uint8_t i;
		const uint8_t *cpointer = (f->font) + ((c - f->startChar) * (f->width));

		// process commands
		switch(c) {
		case 4:
			lcdClear();
			break;
		case '\n':
			y = 128;
			break;

		case '\a':
			lcdSetAddr(x, 0);
			break;

		case '\t':
			i = y / (4*6);
			i = (i+1) * (4*6) - y;
			while (i > 0) {
				if (y > (127)) {	// switch to next line
					switchToNextLine();
					clearLine();
				}
				lcdWrite(0);
				i--;
			}
			break;

		default:
			if (y > (127-6)) {		// switch to next line
				switchToNextLine();
				clearLine();
			}
			for(i=0; i<5; i++) {
				cv = pgm_read_byte(cpointer);
				lcdWrite(cv);
				cpointer++;
			}
			lcdWrite(0);
			break;
		}
	}

	void setStartLine(uint8_t l) {
		call Hpl.controlWrite(1, 0xC0 | l);	// start at line 0
		call Hpl.controlWrite(0, 0xC0 | l);	// start at line 0
	}

	uint8_t currentLine() {
		return (uint8_t)(x - line/8) % 8;
	}

	void clearLine() {
		uint8_t i;

		for(i=0; i<64; i++) {	// clear line
			call Hpl.dataWrite(1, 0);
			call Hpl.dataWrite(0, 0);
		}
	}

	void gotoLine(uint8_t l) {
		lcdSetAddr((uint8_t)(l - line/8)%8, 0);
		clearLine();
	}

	void lcdClear() {
		uint16_t i;

		for(i=0; i<128*8; i++) {
			lcdWrite(0);
			if (y > 127) {		// switch to next line
				switchToNextLine();
			}
		}

		lcdSetAddr(0,0);
		setStartLine(0);
		line = 0;
	}
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

generic module BufferedLcdP(uint8_t LINES, uint8_t LINE_WIDTH) {
	provides interface BufferedLcd;
	uses interface Timer<TMilli> as Timer;
	uses interface HplLcd as Lcd;
	provides interface Init;
}

implementation {
	uint8_t buffer[LINES][LINE_WIDTH];
	bool dirty[LINES];
	uint8_t line;
	uint8_t position;

	enum {
		RAM_LINE_WIDTH	= 0x40,
	};

	void writeChar(char c) {
		buffer[line][position] = c;
		position++;
		dirty[line] = TRUE;

		if (position == LINE_WIDTH) {
			position = 0;
			line = (line + 1) % LINES;
		}
	}

	task void refresh() {
		uint8_t addr;
		uint8_t l;
		uint8_t col;

		for (l=0; l<LINES; l++) {
			if (dirty[l] == TRUE) {
				// goto first character
				addr = (1<<7) | (l * RAM_LINE_WIDTH);
				call Lcd.writeCommand(addr);
				// send line
				for (col=0; col<LINE_WIDTH; col++) {
					call Lcd.writeData(buffer[l][col]);
				}
				dirty[l] = FALSE;
			}
		}
	}

	command error_t Init.init() {
		call BufferedLcd.clear();
		return SUCCESS;
	}

	command void BufferedLcd.autoRefresh(uint32_t period) {
		if (period != 0) {
			call Timer.startPeriodic(period);
		}
		else {
			call Timer.stop();
		}
	}

	command void BufferedLcd.clear() {
		memset(buffer, ' ', sizeof(buffer));
		dirty[0] = TRUE;
		dirty[1] = TRUE;
		call BufferedLcd.goTo(0, 0);
	}

	command void BufferedLcd.write(char *string) {
		while(*string != 0) {
			writeChar(*string);
			string++;
		}
	}

	command void BufferedLcd.write_P(const char *string) {
		char c;

		c = pgm_read_byte(string);
		while(c != 0) {
			writeChar(c);
			string++;
			c = pgm_read_byte(string);
		}
	}

	inline command void BufferedLcd.goTo(uint8_t _line, uint8_t _col) {
		line= _line;
		position = _col;
	}

	inline command void BufferedLcd.forceRefresh() {
		post refresh();
	}

	event void Timer.fired() {
		call BufferedLcd.forceRefresh();
	}
}

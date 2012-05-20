/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

module HplLcdP {
	provides interface Init;
	provides interface HplLcd;
	uses interface GeneralIOPort as Port;
	uses interface BusyWait<TMicro,uint16_t>;
}

implementation {
	enum {
		RS				= 2,
		EN				= 3,
		DATA			= 4,
		DATA_MASK		= (0x0f<<DATA),
		CTL_MASK		= ((1<<RS) | (1<<EN)),
		PORT_MASK		= (CTL_MASK | DATA_MASK),
	};

	//#define nop()	asm volatile("nop;")

	void wait_ms(uint8_t i) {
		while (i != 0) {
			call BusyWait.wait(1000);
			i--;
		}
	}

	void writeNibble(uint8_t byte, bool rs) {
		call Port.write(rs<<RS);		// set mode
		call Port.set(1<<EN);
		call Port.set(byte << DATA);	// set data
		call Port.clear(1<<EN);			// write data
	}

	void write(uint8_t byte, bool rs) {
		writeNibble(byte >> 4, rs);
		writeNibble(byte >> 0, rs);
	}

	command error_t Init.init() {
		call Port.makeOutput(PORT_MASK);

		wait_ms(40);
		write(0x28, FALSE);		// function set
		call BusyWait.wait(40);
		write(0x28, FALSE);		// function set
		call BusyWait.wait(40);
		write(0x0C, FALSE);		// display on
		call BusyWait.wait(40);
		write(0x01, FALSE);		// display clear
		wait_ms(2);
		write(0x06, FALSE);		// entry mode set
		call BusyWait.wait(40);

		return SUCCESS;
	}

	command void HplLcd.writeCommand(uint8_t com) {
		write(com, FALSE);
		call BusyWait.wait(40);
	}

	command void HplLcd.writeData(uint8_t data) {
		write(data, TRUE);
		call BusyWait.wait(40);
	}
}

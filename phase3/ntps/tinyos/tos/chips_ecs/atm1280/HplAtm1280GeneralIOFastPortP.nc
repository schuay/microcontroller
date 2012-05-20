/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @author:	Markus Hartmann <e9808811@student.tuwien.ac.at>
 * @date:	22.01.2012
 */

generic module HplAtm1280GeneralIOFastPortP(uint16_t port_addr, uint16_t ddr_addr, uint16_t pin_addr)
{
	provides interface GeneralIOPort;
}

implementation
{
	#define PIN (*TCAST(volatile uint8_t * ONE, pin_addr))
	#define PORT (*TCAST(volatile uint8_t * ONE, port_addr))
	#define DDR (*TCAST(volatile uint8_t * ONE, ddr_addr))

	inline async command void GeneralIOPort.makeOutput(uint8_t mask) {
		DDR |= mask;
	}

	inline async command void GeneralIOPort.makeInput(uint8_t mask) {
		DDR &= ~mask;
	}

	inline async command void GeneralIOPort.set(uint8_t mask) {
		PORT |= mask;
	}

	inline async command void GeneralIOPort.clear(uint8_t mask) {
		PORT &= ~mask;
	}

	inline async command void GeneralIOPort.toggle(uint8_t mask) {
		PORT ^= mask;
	}

	inline async command void GeneralIOPort.write(uint8_t data) {
		PORT = data;
	}

	inline async command uint8_t GeneralIOPort.read() {
		return PIN;
	}
}

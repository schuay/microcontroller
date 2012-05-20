/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

interface GeneralIOPort {
	async command void makeOutput(uint8_t mask);
	async command void makeInput(uint8_t mask);
	async command void set(uint8_t mask);
	async command void clear(uint8_t mask);
	async command void toggle(uint8_t mask);
	async command void write(uint8_t data);
	async command uint8_t read();
}
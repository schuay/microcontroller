/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.03.2012
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface Sdcard {
	command error_t init();
	event void initDone(error_t error);
	command error_t readBlock(uint32_t blockAddr, uint8_t *buffer);
	event void readBlockDone(uint8_t *buffer, error_t error);
	command bool inserted();
}
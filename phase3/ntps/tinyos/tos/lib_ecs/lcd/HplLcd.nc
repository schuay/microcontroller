/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

interface HplLcd {
	command void writeCommand(uint8_t com);
	command void writeData(uint8_t data);
}

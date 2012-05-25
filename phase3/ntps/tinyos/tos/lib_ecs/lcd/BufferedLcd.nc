/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

#include <avr/pgmspace.h>

interface BufferedLcd {
	/**
	 * @param period	refresh period in ms, set to 0 to disable auto refresh
	 */
	command void autoRefresh(uint32_t period);
	command void clear();
	command void write(char *string);
	command void write_P(const char *string);
	command void goTo(uint8_t line, uint8_t col);
	command void forceRefresh();
}

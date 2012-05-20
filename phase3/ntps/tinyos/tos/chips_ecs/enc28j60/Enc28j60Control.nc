/**
 * @author:	Harald Glanzer, 0727156 TU Wien
 *
 * overhauled by Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 */

#include "enc28j60.h"

// todo: rename to EthernetControl

interface Enc28j60Control {
	event void linkChange(link_status_t status);
}

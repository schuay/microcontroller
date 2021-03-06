/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	27.02.2012
 */

#include "stdo.h"
#include "Atm128Uart.h"

configuration StdoUartC {

}

implementation {
	components MainC;
	components StdoUartP;
	components Atm128Uart1C as Uart;
#ifndef BLOCKING_PRINTF
	components new AsyncQueueC(uint8_t, OUTPUT_BUFFER_SIZE);
#endif

	StdoUartP.Init <- MainC;
	StdoUartP.Uart -> Uart;
	StdoUartP.Control -> Uart;
	StdoUartP.UartControl -> Uart;
#ifndef BLOCKING_PRINTF
	StdoUartP.Queue -> AsyncQueueC;
#endif
}


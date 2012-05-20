/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	27.02.2012
 */

#include "stdo.h"

configuration StdoGlcdC {

}

implementation {
	components MainC;
	components StdoGlcdP;
	components GlcdTextC;
#ifndef BLOCKING_PRINTF
	components new QueueC(uint8_t, OUTPUT_BUFFER_SIZE);
	components new TimerMilliC() as Timer;
#endif

	StdoGlcdP.Init <- MainC;
	StdoGlcdP.GlcdText -> GlcdTextC;
#ifndef BLOCKING_PRINTF
	StdoGlcdP.Queue -> QueueC;
	StdoGlcdP.Timer -> Timer;
#endif
}


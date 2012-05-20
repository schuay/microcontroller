/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	27.02.2012
 */

#include "stdo.h"

static FILE atm128_stdout = FDEV_SETUP_STREAM(TCAST(int (*)(char c, FILE *stream), uart_putchar), NULL, _FDEV_SETUP_WRITE);

module StdoGlcdP @safe() {
	provides interface Init;
#ifndef BLOCKING_PRINTF
	uses interface Queue<uint8_t> as Queue;
	uses interface Timer<TMilli> as Timer;
#endif
	uses interface GlcdText;
}

implementation {
	command error_t Init.init() {
#ifndef BLOCKING_PRINTF
		call Timer.startPeriodic(1000);
#endif
		stdout = &atm128_stdout;
		return SUCCESS;
	}

#ifndef BLOCKING_PRINTF
	task void sendNext() {
		uint8_t c;
		uint8_t i;

		for (i=0; i<10; i++) {
			if (call Queue.empty() == FALSE) {
				c = call Queue.dequeue();

				call GlcdText.writeChar(c);
			}
			else {
				return;
			}
		}

		if (call Queue.empty() == FALSE) {
			post sendNext();
		}
	}

	void printfflush() @C() @spontaneous() {
		post sendNext();
	}
#endif

	int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
#ifndef BLOCKING_PRINTF

		atomic {
			call Queue.enqueue(c);
		}
#else
		call GlcdText.writeChar(c);
#endif
		return SUCCESS;
	}

#ifndef BLOCKING_PRINTF
	event void Timer.fired() {
		if (call Queue.empty() == FALSE) {
			post sendNext();
		}
	}
#endif
}

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	27.02.2012
 */

#include "stdo.h"

static FILE atm128_stdout = FDEV_SETUP_STREAM(TCAST(int (*)(char c, FILE *stream), uart_putchar), NULL, _FDEV_SETUP_WRITE);

module StdoUartP @safe() {
	provides interface Init;
#ifndef BLOCKING_PRINTF
	uses interface UartStream as Uart;
	uses interface AsyncQueue<uint8_t> as Queue;
#else
	uses interface UartByte as Uart;
#endif
	uses interface StdControl as Control;
}

implementation {
#ifndef BLOCKING_PRINTF
	typedef enum {
		UART_IDLE,
		UART_SENDING,
	} state_t;

	state_t state = UART_IDLE;
#endif

	command error_t Init.init() {
		call Control.start();
		stdout = &atm128_stdout;
		return SUCCESS;
	}

#ifndef BLOCKING_PRINTF
	void sendNext() {
		static uint8_t c;

		atomic {
			if (call Queue.empty() == FALSE) {
				c = call Queue.dequeue();

				call Uart.send(&c, 1);
				state = UART_SENDING;
			}
			else {
				state = UART_IDLE;
			}
		}
	}

	async event void Uart.sendDone(uint8_t* buf, uint16_t len, error_t error) {
		sendNext();
	}

	void printfflush() @C() @spontaneous() {
		atomic {
			if ((state == UART_IDLE)) {
				sendNext();
			}
		}
	}
#endif

	int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
#ifndef BLOCKING_PRINTF
		atomic {
			call Queue.enqueue(c);
		}

		printfflush();
#else
		call Uart.send(c);
#endif
		return SUCCESS;
	}

#ifndef BLOCKING_PRINTF
	async event void Uart.receivedByte(uint8_t byte) {}
	async event void Uart.receiveDone(uint8_t* buf, uint16_t len, error_t error) {}
#endif
}

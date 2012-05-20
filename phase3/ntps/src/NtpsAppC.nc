#include "printf.h"
#include "debug.h"

configuration NtpsAppC {

}

implementation {
  components MainC;
  components new TimerMilliC() as Timer;
  components NtpsC;

  /*
   * There are 3 stdo components available (use only one one of them):
   * 1. StdoUartC
   * 	sends "printf" output via uart1
   *
   * 2. StdoGlcdC
   * 	shows "printf" output on the graphical lcd
   *
   * 3. StdoDebugC
   * 	this is mainly for convenience and
   * 	sends "printf" and "debug" output via uart1 in
   * 	debug mode (that is if DEBUG is defined)
   * 	shows "printf" output on the graphical lcd in
   * 	normal mode
   *
   * To enable debug mode without changing code use the
   * following line for compilation (and downloading):
   *
   * >env "CFLAGS=-DDEBUG" make <platform> (install)
   */
  //components StdoUartC;
  //components StdoGlcdC;
  components StdoDebugC;

  NtpsC.Boot -> MainC.Boot;
  NtpsC.Timer -> Timer;
}


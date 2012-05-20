#ifndef DEBUG_H
#define DEBUG_H

#include "printf.h"

#ifdef DEBUG
#warning Debug mode is active
#define debug(...) printf("Debug: ");printf(__VA_ARGS__);printf("\n")
#define StdoDebugC StdoUartC
#else
#define debug(...) do {} while(0)
#define StdoDebugC StdoGlcdC
#endif

#endif
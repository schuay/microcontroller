#include "debug.h"

configuration RtcAppC
{
}

implementation
{
    components MainC;
    components RtcC;

    components LedsC;

    components StdoDebugC;

    RtcC.Boot -> MainC.Boot;
    RtcC.Leds -> LedsC;
}

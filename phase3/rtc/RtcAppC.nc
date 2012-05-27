#include "debug.h"

configuration RtcAppC
{
}

implementation
{
    components MainC;
    components RtcC;

    components LedsC;

    components HplDS1307C;

    components StdoDebugC;

    RtcC.Boot -> MainC.Boot;
    RtcC.Leds -> LedsC;
    RtcC.HplDS1307 -> HplDS1307C;
}

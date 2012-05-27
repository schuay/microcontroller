#include "debug.h"

configuration RtcAppC
{
}

implementation
{
    components MainC;
    components RtcC;

    components LedsC;
    components new TimerMilliC() as Timer0;

    components HplDS1307C;
    components new Atm128I2CMasterC();

    components StdoDebugC;

    RtcC.Boot -> MainC.Boot;
    RtcC.Leds -> LedsC;
    RtcC.Timer -> Timer0;
    RtcC.HplDS1307 -> HplDS1307C;

    HplDS1307C.Resource -> Atm128I2CMasterC;
    HplDS1307C.I2CPacket -> Atm128I2CMasterC;
}

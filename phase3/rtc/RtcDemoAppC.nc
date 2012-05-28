#include "debug.h"

configuration RtcDemoAppC
{
}

implementation
{
    components MainC;
    components RtcDemoC;

    components LedsC;
    components new TimerMilliC() as Timer0;

    components HplDS1307C;
    components new Atm128I2CMasterC();

    components DS1307C;

    components StdoDebugC;

    RtcDemoC.Boot -> MainC.Boot;
    RtcDemoC.Leds -> LedsC;
    RtcDemoC.Timer -> Timer0;
    RtcDemoC.Rtc -> DS1307C;

    DS1307C.Hpl -> HplDS1307C;

    HplDS1307C.Resource -> Atm128I2CMasterC;
    HplDS1307C.I2CPacket -> Atm128I2CMasterC;
}

#include "debug.h"

configuration NtpsAppC
{
}

implementation
{
    components MainC;
    components NtpsC;

    components LedsC;

    components new TimerMilliC() as Timer0;
    components TouchScreenC;
    components UserInterfaceC;

    components Atm128Uart0C as UartDevC;
    components GpsTimerParserC;

    components StdoDebugC;

    NtpsC.Boot -> MainC.Boot;
    NtpsC.UserInterface -> UserInterfaceC;
    NtpsC.GpsTimerParser -> GpsTimerParserC;
    NtpsC.Leds -> LedsC;

    GpsTimerParserC.UartStream -> UartDevC;
    GpsTimerParserC.UartControl -> UartDevC.UartControl;
    GpsTimerParserC.Uart -> UartDevC;

    UserInterfaceC.Timer -> Timer0;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;
}

#include "printf.h"
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

    components StdoDebugC;

    NtpsC.Boot -> MainC.Boot;
    NtpsC.UserInterface -> UserInterfaceC;
    NtpsC.UartStream -> UartDevC;
    NtpsC.UartControl -> UartDevC.UartControl;
    NtpsC.Uart -> UartDevC;
    NtpsC.Leds -> LedsC;

    UserInterfaceC.Timer -> Timer0;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;
}

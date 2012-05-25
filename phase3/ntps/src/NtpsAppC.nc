#include "printf.h"
#include "debug.h"

configuration NtpsAppC
{
}

implementation
{
    components MainC;
    components new TimerMilliC() as Timer0;
    components NtpsC;
    components UserInterfaceC;
    components TouchScreenC;
    components StdoDebugC;

    NtpsC.Boot -> MainC.Boot;
    NtpsC.UserInterface -> UserInterfaceC;

    UserInterfaceC.Timer -> Timer0;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;
}

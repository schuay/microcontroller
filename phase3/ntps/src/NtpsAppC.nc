#include "printf.h"
#include "debug.h"

configuration NtpsAppC
{
}

implementation
{
    components MainC;
    components new TimerMilliC() as Timer;
    components NtpsC;
    components UserInterfaceC;
    components TouchScreenC;
    components StdoDebugC;

    NtpsC.Boot -> MainC.Boot;
    NtpsC.Timer -> Timer;
    NtpsC.UserInterface -> UserInterfaceC;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;
}

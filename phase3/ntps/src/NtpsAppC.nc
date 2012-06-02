#include "debug.h"
#include "UdpConfig.h"

configuration NtpsAppC
{
}

implementation
{
    components StdoDebugC; /* ECS implementation forces us to defines
                            * this before PlatformSerialC. */
    components MainC;
    components NtpsC;

    components LedsC;

#ifndef NOEXTRAS
    components new TimerMilliC() as Timer0;
#endif
    components new TimerMilliC() as Timer1;
#ifndef NOEXTRAS
    components TouchScreenC;
    components UserInterfaceC;
#endif

    components PlatformSerialC as UartDevC;
    components GpsTimerParserC;

    components new Atm128I2CMasterC();
    components HplDS1307C;
    components DS1307C;

#ifndef NOEXTRAS
    components new UdpC(UDP_PORT);
    components Enc28j60C as EthernetC;
    components LlcTransceiverC;
    components IpTransceiverC;
    components PingC;
#endif

    components TimeC;

    NtpsC.Boot -> MainC.Boot;
#ifndef NOEXTRAS
    NtpsC.UserInterface -> UserInterfaceC;
#endif
    NtpsC.GpsTimerParser -> GpsTimerParserC;
    NtpsC.Leds -> LedsC;
    NtpsC.Rtc -> DS1307C;
    NtpsC.Timer -> Timer1;
    NtpsC.Time -> TimeC;

#ifndef NOEXTRAS
    NtpsC.UdpSend -> UdpC;
    NtpsC.UdpReceive -> UdpC;
    NtpsC.Control -> EthernetC;
    LlcTransceiverC.Mac -> EthernetC;
    NtpsC.IpControl -> IpTransceiverC;
#endif

    DS1307C.Hpl -> HplDS1307C;

    HplDS1307C.Resource -> Atm128I2CMasterC;
    HplDS1307C.I2CPacket -> Atm128I2CMasterC;

    GpsTimerParserC.UartStream -> UartDevC;
    GpsTimerParserC.UartControl -> UartDevC.UartControl;
    GpsTimerParserC.Uart -> UartDevC;
    GpsTimerParserC.Time -> TimeC;

#ifndef NOEXTRAS
    UserInterfaceC.Timer -> Timer0;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;
#endif
}

#include "debug.h"
#include "UdpConfig.h"

configuration NtpsAppC
{
}

implementation
{
    components MainC;
    components NtpsC;

    components LedsC;

    components new TimerMilliC() as Timer0;
    components new TimerMilliC() as Timer1;
    components TouchScreenC;
    components UserInterfaceC;

    components Atm128Uart0C as UartDevC;
    components GpsTimerParserC;

    components new Atm128I2CMasterC();
    components HplDS1307C;
    components DS1307C;

    components new UdpC(UDP_PORT);
    components Enc28j60C as EthernetC;
    components LlcTransceiverC;
    components IpTransceiverC;
    components PingC;

    components StdoDebugC;

    NtpsC.Boot -> MainC.Boot;
    NtpsC.UserInterface -> UserInterfaceC;
    NtpsC.GpsTimerParser -> GpsTimerParserC;
    NtpsC.Leds -> LedsC;
    NtpsC.Rtc -> DS1307C;
    NtpsC.Timer -> Timer1;

    NtpsC.UdpSend -> UdpC;
    NtpsC.UdpReceive -> UdpC;
    NtpsC.Control -> EthernetC;
    LlcTransceiverC.Mac -> EthernetC;
    NtpsC.IpControl -> IpTransceiverC;

    DS1307C.Hpl -> HplDS1307C;

    HplDS1307C.Resource -> Atm128I2CMasterC;
    HplDS1307C.I2CPacket -> Atm128I2CMasterC;

    GpsTimerParserC.UartStream -> UartDevC;
    GpsTimerParserC.UartControl -> UartDevC.UartControl;
    GpsTimerParserC.Uart -> UartDevC;

    UserInterfaceC.Timer -> Timer0;
    UserInterfaceC.TouchScreen -> TouchScreenC.TouchScreen;
    UserInterfaceC.Glcd -> TouchScreenC.Glcd;

}

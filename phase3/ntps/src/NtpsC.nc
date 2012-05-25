#include <Atm128Uart.h>

module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
    uses interface StdControl as Uart;
    uses interface UartStream;
    uses interface UartControl;
    uses interface Leds;
}

implementation
{
    event void Boot.booted(void)
    {
        timedate_t gps_time;
        rtc_time_t rtc_time;

        debug("%s\r\n", __PRETTY_FUNCTION__);
        debug("Node ID %d\r\n", TOS_NODE_ID);

        call UserInterface.init();

        /* TODO */
        call UserInterface.setTimeGPS(gps_time);
        call UserInterface.setTimeRTC(rtc_time);

        call Uart.start();

        call UartControl.setSpeed(4800);
        call UartControl.setParity(TOS_UART_PARITY_NONE);
    }

    event void UserInterface.setToGPSPressed(void)
    {
        debug("Set to GPS pressed.\r\n");
    }

    event void UserInterface.setToOffsetPressed(void)
    {
        debug("Set to Offset pressed.\r\n");
    }

    async event void UartStream.receivedByte(uint8_t byte)
    {
        debug("Received: %d\r\n", byte);
        call Leds.set(byte);
    }

    async event void UartStream.sendDone(uint8_t *buf __attribute__ ((unused)),
                                         uint16_t len __attribute__ ((unused)),
                                         error_t error __attribute ((unused)))
    {
    }

    async event void UartStream.receiveDone(uint8_t* buf __attribute__ ((unused)),
                                            uint16_t len __attribute__ ((unused)),
                                            error_t error __attribute__ ((unused)))
    {
    }
}

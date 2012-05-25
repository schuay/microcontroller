module GpsTimerParserC
{
    uses interface StdControl as Uart;
    uses interface UartStream;
    uses interface UartControl;

    provides interface GpsTimerParser;
}

implementation
{
    command void GpsTimerParser.startService(void)
    {
        call Uart.start();

        call UartControl.setSpeed(4800);
        call UartControl.setParity(TOS_UART_PARITY_NONE);
    }

    command void GpsTimerParser.stopService(void)
    {
        call Uart.stop();
    }

    async event void UartStream.receivedByte(uint8_t byte)
    {
        debug("Received: %d\r\n", byte);
    }

    async event void UartStream.sendDone(uint8_t *buf __attribute__ ((unused)),
                                         uint16_t len __attribute__ ((unused)),
                                         error_t error __attribute ((unused)))
    {
        /* Nothing to send. */
    }

    async event void UartStream.receiveDone(uint8_t* buf __attribute__ ((unused)),
                                            uint16_t len __attribute__ ((unused)),
                                            error_t error __attribute__ ((unused)))
    {
        /* Not used. */
    }
}

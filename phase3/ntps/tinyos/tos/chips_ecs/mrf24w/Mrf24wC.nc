/**
 * @author:	Christian Mauser, 0625688 and Alexander Heinisch, 0627820 (TU Wien)
 *
 */

configuration Mrf24wC {
	provides interface Mac;
	provides interface WlanControl;
	provides interface SplitControl;
}

implementation {
	components Mrf24wP;
	components HplAtm128GeneralIOC as IO;
	components Atm128SpiC as SPI;
	components HplAtm128InterruptC;

	Mrf24wP.Mac = Mac;
	Mrf24wP.WlanControl = WlanControl;
	Mrf24wP.intWLAN -> HplAtm128InterruptC.Int0;
	Mrf24wP.SpiByte -> SPI.SpiByte;
	Mrf24wP.Resource -> SPI.Resource[0];
	Mrf24wP.SlaveSelect -> IO.PortB0;
	Mrf24wP.resetPin -> IO.PortB4;
	Mrf24wP.SplitControl = SplitControl;
}

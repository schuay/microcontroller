/**
 * @author:	Harald Glanzer, 0727156 TU Wien
 *
 * overhauled by Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 */

configuration Enc28j60C {
	provides interface Mac;
	provides interface SplitControl;
	provides interface Enc28j60Control;
}

implementation {
	components Enc28j60P;
	components HplAtm128GeneralIOC as IO;
	components Atm128SpiC as SPI;
	components HplAtm128InterruptC;

	Enc28j60P.Mac = Mac;
	Enc28j60P.SpiByte -> SPI.SpiByte;
	Enc28j60P.Resource -> SPI.Resource[0];
	Enc28j60P.ssETH -> IO.PortB0;
	Enc28j60P.rstETH -> IO.PortB4;
	Enc28j60P.intETH -> HplAtm128InterruptC.Int0;
	Enc28j60P.SplitControl = SplitControl;
	Enc28j60P.Enc28j60Control = Enc28j60Control;
}

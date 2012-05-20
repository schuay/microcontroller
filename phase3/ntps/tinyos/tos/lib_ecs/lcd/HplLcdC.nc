/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

configuration HplLcdC {
	provides interface HplLcd;
}

implementation {
	components MainC;
	components HplAtm128GeneralIOFastPortC;
	components HplLcdP;
	components BusyWaitMicroC;

	HplLcdP.Port -> HplAtm128GeneralIOFastPortC.PortC;
	HplLcdP.Init <- MainC.SoftwareInit;
	HplLcdP.HplLcd = HplLcd;
	HplLcdP.BusyWait -> BusyWaitMicroC;
}

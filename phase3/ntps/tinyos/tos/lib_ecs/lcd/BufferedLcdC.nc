/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

configuration BufferedLcdC {
	provides interface BufferedLcd;
}

implementation {
	components MainC;
	components new TimerMilliC() as Timer;
	components new BufferedLcdP(2, 16);
	components HplLcdC;

	BufferedLcd = BufferedLcdP.BufferedLcd;
	BufferedLcdP.Timer -> Timer;
	BufferedLcdP.Lcd -> HplLcdC;
	BufferedLcdP.Init <- MainC.SoftwareInit;
}

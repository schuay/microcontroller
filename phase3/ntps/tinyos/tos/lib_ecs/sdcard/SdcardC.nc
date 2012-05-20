/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.03.2012
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

configuration SdcardC {
	provides interface Sdcard;
}

implementation {
	components SdcardP;
	components Atm128SpiC;
	components HplAtm128GeneralIOC as IO;

	Sdcard = SdcardP;
	SdcardP.SpiByte -> Atm128SpiC.SpiByte;
	SdcardP.Resource -> Atm128SpiC.Resource[0];
	SdcardP.cs -> IO.PortG1;
	SdcardP.cd -> IO.PortG2;
}


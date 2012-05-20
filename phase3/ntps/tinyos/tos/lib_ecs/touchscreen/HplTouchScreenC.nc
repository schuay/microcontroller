/**
 * Configuration for Touch Screen Low-Level functions
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      13.02.2012
 */

configuration HplTouchScreenC
{
  provides interface HplTouchScreen;
}
implementation
{
  components new AdcReadStreamClientC();
  components MainC;
  components HplTouchScreenP;
  components HplAtm128GeneralIOC as IO;
  
  HplTouchScreenP.HplTouchScreen = HplTouchScreen;

  HplTouchScreenP.ReadStream -> AdcReadStreamClientC;
  HplTouchScreenP.AdcConfig <- AdcReadStreamClientC;
  HplTouchScreenP.DRIVE_A -> IO.PortG3;
  HplTouchScreenP.DRIVE_B -> IO.PortG4;
  HplTouchScreenP.ADC_X -> IO.PortF0;
  HplTouchScreenP.ADC_Y -> IO.PortF1;
}

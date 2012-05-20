/**
 * Configuration for KS0108 GLCD Display
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 */

configuration HplKS0108C
{
  provides interface HplKS0108;
}
implementation
{
  components HplKS0108P;
  components HplAtm128GeneralIOC as IO;
  components HplAtm128GeneralIOFastPortC;
  components BusyWaitMicroC;
  
  HplKS0108P.HplKS0108 = HplKS0108;
  
  HplKS0108P.CS_0 -> IO.PortE2;
  HplKS0108P.CS_1 -> IO.PortE3;
  HplKS0108P.RS -> IO.PortE4;
  HplKS0108P.RW -> IO.PortE5;
  HplKS0108P.EN -> IO.PortE6;
  HplKS0108P.RST -> IO.PortE7;

  HplKS0108P.Data -> HplAtm128GeneralIOFastPortC.PortA;

  HplKS0108P.BusyWait -> BusyWaitMicroC;
}

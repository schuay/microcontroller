/**
 * Configuration for Touch Screen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      14.02.2012
 */

configuration TouchScreenC
{
  provides interface TouchScreen;
  provides interface Glcd;
}
implementation
{
  components MainC;
  components GlcdC;
  components TouchScreenP;
  components HplTouchScreenC;

  TouchScreen = TouchScreenP.TouchScreen;
  GlcdC.Glcd = Glcd;
  TouchScreenP.Glcd -> GlcdC.Glcd;
  TouchScreenP.Hpl -> HplTouchScreenC;
  MainC.SoftwareInit -> TouchScreenP.Init;
}

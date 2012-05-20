/**
 * High level implementation for KS0108 Glcd
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 */

configuration GlcdTextC
{
  provides interface GlcdText;
}

implementation
{
  components MainC;
  components GlcdTextP;
  components HplKS0108C;

  GlcdText = GlcdTextP.GlcdText;
  GlcdTextP.Hpl -> HplKS0108C;
  MainC.SoftwareInit -> GlcdTextP.Init;
}

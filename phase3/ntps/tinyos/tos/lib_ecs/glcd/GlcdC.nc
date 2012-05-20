/**
 * High level implementation for KS0108 Glcd
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 */

configuration GlcdC
{
  provides interface Glcd;
}

implementation
{
  components MainC;
  components GlcdP;
  components HplKS0108C;

  Glcd = GlcdP.Glcd;
  GlcdP.Hpl -> HplKS0108C;
  MainC.SoftwareInit -> GlcdP.Init;
}

/**
 * @author Markus Hartmann e988811@student.tuwien.ac.at
 */

configuration MP3C{

  provides interface MP3;

}

implementation{

  components MP3P;
  components new SoftSPIMasterC() as SPI0;
  //components SoftSPIC as SoftSPI0;
  components new TimerMilliC() as Timer0;
  components HplAtm128GeneralIOC as IO;

  MP3 = MP3P;
  MP3P.Timer0 -> Timer0;

  MP3P.CS -> IO.PortD1;
  MP3P.RST -> IO.PortD2;
  MP3P.DREQ -> IO.PortF2;
  MP3P.BSYNC -> IO.PortF3;
  MP3P.Measure0 -> IO.PortC1;

  MP3P.SPI0 -> SPI0; /* connect resource */
  MP3P.SoftSPI0 -> SPI0; /* connect SoftSPI interface */
  //MP3P.SoftSPI -> SoftSPIC;

}


#include "SoftSPI.h"
configuration SoftSPIC{
  provides interface SoftSPI;
}

implementation{
  components SoftSPIP;
  components HplAtm128GeneralIOC as IO;

  SoftSPI = SoftSPIP;

  /****************************************
   * Check SoftSPI.h for correct PIN/PORT *
   ****************************************/

  SoftSPIP.spiSCK -> IO.PortD3;
  SoftSPIP.spiMISO -> IO.PortD4;
  SoftSPIP.spiMOSI -> IO.PortD5;
}

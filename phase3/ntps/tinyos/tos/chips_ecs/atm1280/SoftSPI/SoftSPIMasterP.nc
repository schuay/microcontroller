 /*
 * @author Markus Hartmann (e9808811@student.tuwien.ac.at)
 * @date 2011-08-25
 */

#include "SoftSPIMaster.h"
configuration SoftSPIMasterP{
  provides interface SoftSPI[uint8_t id];
  provides interface Resource[uint8_t id];
  provides interface ResourceRequested[uint8_t id];
  uses interface ResourceConfigure[uint8_t id];
}
implementation{
  components SoftSPIImplP;
  components new FcfsArbiterC(UQ_SOFT_SPI_MASTER)as Arbiter;
  components SoftSPIP;
  components HplAtm128GeneralIOC as IO;

  /****************************************
   * Check SoftSPI.h for correct PIN/PORT *
   ****************************************/
  SoftSPI = SoftSPIImplP;
  Resource = Arbiter;
  ResourceRequested = Arbiter;
  ResourceConfigure = Arbiter;

  SoftSPIImplP.ArbiterInfo -> Arbiter;
  SoftSPIImplP.SoftSPI -> SoftSPIP;

  SoftSPIP.spiSCK -> IO.PortD3;
  SoftSPIP.spiMISO -> IO.PortD4;
  SoftSPIP.spiMOSI -> IO.PortD5;
}

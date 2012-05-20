 /*
 * @author Markus Hartmann (e9808811@student.tuwien.ac.at)
 * @date 2011-08-25
 */

#include "SoftSPIMaster.h"
generic configuration SoftSPIMasterC(){
  provides interface SoftSPI;
  provides interface Resource;
  provides interface ResourceRequested;
  uses interface ResourceConfigure;
}
implementation{
  components SoftSPIMasterP;

  enum { RESOURCE_ID = unique( UQ_SOFT_SPI_MASTER ) };

  Resource = SoftSPIMasterP.Resource[RESOURCE_ID];
  ResourceRequested = SoftSPIMasterP.ResourceRequested[RESOURCE_ID];
  ResourceConfigure = SoftSPIMasterP.ResourceConfigure[RESOURCE_ID];
  SoftSPI = SoftSPIMasterP.SoftSPI[RESOURCE_ID];
}

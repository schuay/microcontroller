module MotePlatformC @safe()
{
  provides interface Init as PlatformInit;
  uses interface Init as SubInit;
}
implementation {

  command error_t PlatformInit.init() {
    return call SubInit.init();
  }

  default command error_t SubInit.init() {
    return SUCCESS;
  }
}

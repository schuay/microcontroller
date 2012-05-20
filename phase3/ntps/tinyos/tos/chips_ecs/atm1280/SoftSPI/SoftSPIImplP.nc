 /*
 * @author Markus Hartmann (e9808811@student.tuwien.ac.at)
 * @date 2011-08-25
 */

module SoftSPIImplP{
  provides interface SoftSPI as SoftSPIMaster[uint8_t id];
  uses interface SoftSPI;
  uses interface ArbiterInfo;
}
implementation{
  uint8_t current_id;

  inline async command error_t SoftSPIMaster.sendByte[uint8_t id]( uint8_t msg ){
    if ( call ArbiterInfo.userId() == id ){
	call SoftSPI.sendByte( msg );
	atomic current_id = id;
	return SUCCESS;
      }
      return FAIL;
  }

  inline async command error_t SoftSPIMaster.receiveByte[uint8_t id]( uint8_t *data ){
    if ( call ArbiterInfo.userId() == id ){
      call SoftSPI.receiveByte( data );
      atomic current_id = id;
      return SUCCESS;
    }
    return FAIL;
  }
}

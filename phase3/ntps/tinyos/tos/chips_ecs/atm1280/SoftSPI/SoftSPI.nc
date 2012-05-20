interface SoftSPI{

  /********************************************
   * values are read/written on rising edge   *
   * see SoftSPI.h for pin/port configuration *
   ********************************************/
  
  /* send one Byte */
  inline async command error_t sendByte( uint8_t msg );

  /* receive one Byte */
  inline async command error_t receiveByte( uint8_t *data );
  
}

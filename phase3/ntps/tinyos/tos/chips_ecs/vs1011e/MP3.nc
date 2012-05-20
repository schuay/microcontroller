interface MP3{
  command error_t init( void );
  command error_t writeRegister( uint8_t mp3Register, uint16_t mp3Cmd  );
  command uint16_t readRegister( uint8_t mp3Register );
  command error_t writeData( uint8_t *data, uint8_t len );
  command void sineTestStart(void);
  command void sineTestStop(void);
  command error_t setVolume( uint8_t volume );
  command bool isReady( void );
}

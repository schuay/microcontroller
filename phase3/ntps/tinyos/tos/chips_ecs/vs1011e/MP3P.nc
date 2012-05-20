/**
 * @author Markus Hartmann e988811@student.tuwien.ac.at
 */

module MP3P{
  uses interface Timer<TMilli> as Timer0;

  uses interface GeneralIO as CS;
  uses interface GeneralIO as RST;
  uses interface GeneralIO as DREQ;
  uses interface GeneralIO as BSYNC;
  uses interface GeneralIO as Measure0;

  uses interface Resource as SPI0;
  uses interface SoftSPI as SoftSPI0;
  //uses interface SoftSPI;
  provides interface MP3;
}

implementation{

  enum mp3Reg{MODE, STATUS, BASS, CLOCKF, \
	      DECODE_TIME, AUDATA, WRAM, WRAMADDR, \
	      HDAT0, HDAT1, AIADDR, VOLUME, \
	      AICTRL0, AICTRL1, AICTRL2, AICTRL3};

  enum mp3Mode{SM_DIFF, SM_LAYER12, SM_RESET, SM_OUTOFWAV, \
	       SM_SETTOZERO1, SM_TESTS, SM_STREAM, SM_SETTOZERO2, \
	       SM_DACT, SM_SDIORD, SM_SDISHARE, SM_SDINEW, SM, \
	       SETTOZERO3, SM_SETTOZERO4 };

  enum {MP3_WRITE = 2, MP3_READ};

  command error_t MP3.init( void ){

    call Timer0.startOneShot( 1000 );

    /* set pins */
    call CS.makeOutput(); 
    call RST.makeOutput(); 
    call BSYNC.makeOutput();
    call CS.set();
    call RST.set();
    call BSYNC.set();
    call DREQ.makeInput();
    PORTC = 4;   
    /* reset */
    call RST.clr();
    call RST.set();
    while ( !call MP3.isReady() ){
      ; /* ~380us */
    }
    PORTC = 5;
    /* set clock */
    call MP3.writeRegister( CLOCKF, 12500 );
    while ( !call MP3.isReady() ){
      ; /* ~50us */
    }
    PORTC = 6;
    /* set native mode */
    call MP3.writeRegister( MODE, (1<<SM_SDINEW) );
    while ( !call MP3.isReady() ){
      ; /* ~50us */
    }
   
    /* set volume to acceptable scale */
    call MP3.setVolume( 230 );
   
    if ( call Timer0.getNow() > 50){
      return FAIL;
    }

    call Timer0.stop();
    return SUCCESS;
  } 

  command bool MP3.isReady( void ){
    return call DREQ.get();
  }

  command error_t MP3.setVolume( uint8_t volume ){
    if ( volume == 0 ){
      return call MP3.writeRegister( VOLUME, 0xFEFE ); /* 0xFFFF = analog power down mode */		
    }
    return call MP3.writeRegister( VOLUME, ( (255-volume)*256 + (255-volume)) );
  }

  command uint16_t MP3.readRegister( uint8_t mp3Register ){
    uint8_t tmp;
    uint16_t ret;

    call SPI0.immediateRequest();
    call CS.clr();

    atomic{
      call SoftSPI0.sendByte( MP3_READ );
      call SoftSPI0.sendByte( mp3Register );
      call SoftSPI0.receiveByte( &tmp ); /* read high byte */
      ret = tmp;
      ret <<= 8;
      call SoftSPI0.receiveByte( &tmp ); /* read lower byte */
      ret |= tmp;
    }
    call CS.set();
    call SPI0.release();
    return ret;
  }

  command error_t MP3.writeRegister( uint8_t mp3Register, uint16_t mp3Cmd  ){
    if ( !call SPI0.immediateRequest() ){
      return EBUSY;
    }    
    
    call CS.clr();
    call SoftSPI0.sendByte( MP3_WRITE );
    call SoftSPI0.sendByte( mp3Register );
    call SoftSPI0.sendByte( (mp3Cmd>>8) ); /* send high byte */
    call SoftSPI0.sendByte( mp3Cmd ); /* send low byte */
    call CS.set();
    call SPI0.release();    
    return SUCCESS;
  }

  command error_t MP3.writeData( uint8_t *data, uint8_t len ){
    uint8_t i;

    call SPI0.immediateRequest(); 
    /* to slow for check??? */
    /*if ( !call SPI0.immediateRequest() ){
      return EBUSY;
      }*/
    
    call BSYNC.clr();
    atomic {
      for ( i=0; i< len; i++){
	call SoftSPI0.sendByte( data[i]  );
      }
    }
    call BSYNC.set();
    call SPI0.release();    
    return SUCCESS;
  }

  command void MP3.sineTestStart(void){
    /* data sequence to start Sine Test */
    uint8_t startSequ[] = { 0x53, 0xef, 0x6e, 0xcc, 0x00, 0x00, 0x00, 0x00 };
    
    /* make sure pins are set */
    call CS.makeOutput(); 
    call RST.makeOutput(); 
    call BSYNC.makeOutput();
    call CS.set();
    call RST.set();
    call BSYNC.set();
    call DREQ.makeInput();
    
    /* reset */
    call RST.clr();
    while ( call DREQ.get() == 0 ){
      ; /* wait */
    }

    call RST.set();
    while ( call DREQ.get() == 0 ){
      ; /* wait */
    }

    /* set clock */
    call MP3.writeRegister( CLOCKF, 12500 );
    while ( call DREQ.get() == 0 ){
      ; /* wait */
    }

    /* set volume to acceptable scale */
    call MP3.writeRegister( VOLUME, 14000 );
    while ( call DREQ.get() == 0 ){
      ; /* wait */
    }

    /* set modes */
    call MP3.writeRegister(MODE, ((1<<SM_SDINEW)|(1<<SM_TESTS)) );
    while ( call DREQ.get() == 0 ){
      ; /* wait */
    }
    
    /* write data sequence */
    call MP3.writeData( startSequ, 8 );
  }

  command void MP3.sineTestStop(void){
    /* data sequence to stop Sine Test */
    uint8_t stopSequ[] = { 0x45, 0x78, 0x69, 0x74, 0x00, 0x00, 0x00, 0x00 };

    /* write data sequence */
    call MP3.writeData( stopSequ, 8 );

    /* set back to native mode */
    call MP3.writeRegister( MODE, (1<<SM_SDINEW) );
  }

  event void Timer0.fired(){
  }
  
  event void SPI0.granted(){
  }
}

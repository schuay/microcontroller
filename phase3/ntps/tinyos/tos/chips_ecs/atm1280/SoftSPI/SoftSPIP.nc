#include "SoftSPI.h"

module SoftSPIP{

  uses interface GeneralIO as spiSCK;
  uses interface GeneralIO as spiMOSI;
  uses interface GeneralIO as spiMISO;

  provides interface SoftSPI;

}

implementation{

  inline async command error_t SoftSPI.sendByte(uint8_t msg){

    /* set ports */
    call spiSCK.makeOutput();
    call spiMOSI.makeOutput();

    asm volatile (";*****************************\n"
		  "bst %0,7; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset7\n"
		  "cbi %1, %2\n"
		  "tset7:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,6; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset6\n"
		  "cbi %1, %2\n"
		  "tset6:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,5; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset5\n"
		  "cbi %1, %2\n"
		  "tset5:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,4; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset4\n"
		  "cbi %1, %2\n"
		  "tset4:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,3; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset3\n"
		  "cbi %1, %2\n"
		  "tset3:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,2; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset2\n"
		  "cbi %1, %2\n"
		  "tset2:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,1; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset1\n"
		  "cbi %1, %2\n"
		  "tset1:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "bst %0,0; store bit in T flag\n"
		  "sbi %1, %2; set MOSI to high\n"
		  "cbi %1, %3; SCK to LOW\n"
		  "brts tset0\n"
		  "cbi %1, %2\n"
		  "tset0:\n"
		  ";already set - wos not deleted\n"
		  "sbi %1, %3; SCK to high\n"
		  ";*****************************\n"
		  :: "r" (msg), "I" (_SFR_IO_ADDR(SPI_PORT)), "I" (SPI_MOSI), "I" (SPI_SCK) );
    return SUCCESS;
  }

  inline async command error_t SoftSPI.receiveByte( uint8_t *data ){

    uint8_t ret; /*  value */
    
    /* set ports */    
    call spiSCK.makeOutput();
    call spiMISO.makeInput();

    asm volatile (";init return value and clock\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "ldi %0, 0x00; ldi ret, 0x00\n"
		  "nop;\n"
		  ";---------------\n"
		  ";read byte\n"
		  ";---------------\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b10000000; sbr ret, 0b10000000; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b01000000; sbr ret, 0b01000000; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00100000; sbr ret, 0b00100000; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00010000; sbr ret, 0b00010000; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00001000; sbr ret, 0b00001000; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00000100; sbr ret, 0b00000100; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00000010; sbr ret, 0b00000010; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  ";*****************************\n"
		  "sbi %1, %4; sbi port, sck; SCK to high\n"
		  "sbic %2, %3; sbic pin, miso; bit is already set to 0\n"
		  "sbr %0, 0b00000001; sbr ret, 0b00000001; set bit to 1\n"
		  "cbi %1, %4; SCK to LOW; cbi port, sck\n"
		  "nop\n"
		  "nop\n"
		  ";*****************************\n"
		  : "=d" (ret) : "I" (_SFR_IO_ADDR(SPI_PORT)), "I" (_SFR_IO_ADDR(SPI_PIN)), "I" (SPI_MISO), "I" (SPI_SCK) );

    memcpy( data, &ret, 1 );
    return SUCCESS;
  }
}

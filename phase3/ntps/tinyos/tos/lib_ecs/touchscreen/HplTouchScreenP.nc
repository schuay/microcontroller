/**
 * Hpl implementation for Touch Screen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      13.02.2012
 */

#include "HplTouchScreen.h"

#define TOUCHSCREEN_ADC_RESULTS 4

module HplTouchScreenP
{
  provides interface Atm128AdcConfig as AdcConfig;
  provides interface HplTouchScreen;

  uses interface ReadStream<uint16_t>;
  uses interface GeneralIO as DRIVE_A;
  uses interface GeneralIO as DRIVE_B;
  uses interface GeneralIO as ADC_X;
  uses interface GeneralIO as ADC_Y;
}

implementation
{
  enum{TOUCH_SCREEN_IDLE, TOUCH_SCREEN_READ_X, TOUCH_SCREEN_READ_Y};

  uint8_t adc_channel;                            /* 0 = x // 1 = y */
  uint16_t adc_results[TOUCHSCREEN_ADC_RESULTS];  /* buffer for results */
  touchscreen_raw_t *raw_data_ptr;                /* external data buffer */
  uint8_t touchscreen_state;                      /* state for reading x/y */

  /************* PROTOTYPES **********/
  void set_read_x(void);
  void set_read_y(void);
  uint16_t mean_of_four( uint16_t *results );

  command error_t HplTouchScreen.init(void){
    call DRIVE_A.makeOutput();
    call DRIVE_B.makeOutput();
    call ADC_X.makeInput();
    call ADC_Y.makeInput();
    touchscreen_state = TOUCH_SCREEN_IDLE;
    set_read_x();
    return SUCCESS;
  }

  command error_t HplTouchScreen.readRaw(touchscreen_raw_t *raw_data)
  {
    error_t error;
    if (touchscreen_state != TOUCH_SCREEN_IDLE){
      return EBUSY;
    }
    set_read_x();
    touchscreen_state = TOUCH_SCREEN_READ_X;
    call ReadStream.postBuffer(adc_results, TOUCHSCREEN_ADC_RESULTS);
    error = call ReadStream.read(100);
    if (error != SUCCESS){
      touchscreen_state = TOUCH_SCREEN_IDLE;
      return error;
    }

    raw_data_ptr = raw_data;
    return SUCCESS;
  }

  event void ReadStream.bufferDone(error_t result, uint16_t* buf, uint16_t count)
  {
    ;
  }

  event void ReadStream.readDone(error_t result, uint32_t usActualPeriiod)
  {   
    uint16_t temp;
    switch (touchscreen_state){
    case (TOUCH_SCREEN_READ_X):
      temp = mean_of_four(adc_results);
      memcpy(&raw_data_ptr->x, &temp, sizeof(temp));
      set_read_y();
      touchscreen_state = TOUCH_SCREEN_READ_Y;
      call ReadStream.postBuffer(adc_results, TOUCHSCREEN_ADC_RESULTS);
      call ReadStream.read(100);
      break;
    case (TOUCH_SCREEN_READ_Y):
      temp = mean_of_four(adc_results);
      memcpy(&raw_data_ptr->y, &temp, sizeof(temp));
      touchscreen_state = TOUCH_SCREEN_IDLE;
      signal HplTouchScreen.rawDataReady();
      break;
    default:
      touchscreen_state = TOUCH_SCREEN_IDLE;
      break;
    }   
  }

  async command uint8_t AdcConfig.getChannel()
  {
    return adc_channel;
  }

  async command uint8_t AdcConfig.getRefVoltage()
  {
    return ATM128_ADC_VREF_AVCC;
  }

  async command uint8_t AdcConfig.getPrescaler()
  {
    return ATM128_ADC_PRESCALE_128;
  }

  /************* PRIVATE *************/

  void set_read_x(void)
  {
    call DRIVE_A.set();
    call DRIVE_B.clr();
    atomic{ adc_channel = ATM128_ADC_SNGL_ADC0; }
  }

  void set_read_y(void)
  {
    call DRIVE_B.set();
    call DRIVE_A.clr();   
    atomic{ adc_channel = ATM128_ADC_SNGL_ADC1; }
  }
  
  uint16_t mean_of_four( uint16_t *results ) {
    uint16_t tmp;
    if ( results[0] > results[1] ){
      tmp = results[1];
      results[1] = results[0];
      results[0] = tmp;
    }
    if ( results[2] > results[3] ){
      tmp = results[3];
      results[3] = results[2];
      results[2] = tmp;
    }
    
    if ( results[0] < results[2] ){
      tmp = results[2];
    } else {
      tmp = results[0];
    }
    if ( results[1] > results[3] ){
      tmp += results[3];
    } else {
      tmp += results[1];
    }
    
    tmp >>= 1;
	  return tmp;
  }
  
}

/**
 * High level implememtation for Touch Screen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      14.02.2012
 */

#include "TouchScreen.h"

module TouchScreenP
{
  uses interface HplTouchScreen as Hpl;
  uses interface Glcd;

  provides interface TouchScreen;
  provides interface Init; 
}
implementation
{
  touchscreen_raw_t raw_data; /* buffer for adc raw data from x/y */
  ts_coordinates_t *coord_ptr;

  enum{TS_READY, TS_BUSY};

  uint8_t ts_state;
  int8_t offset_x;
  int8_t offset_y;

  /************* PROTOTYPES **********/
  void calculate_coordinates(void);

  command error_t TouchScreen.calibrate(int8_t x_offset, int8_t y_offset)
  {
    offset_x = x_offset;
    offset_y = y_offset;
    return SUCCESS;
  }

  command error_t TouchScreen.getCoordinates( ts_coordinates_t *xy )
  {    
    error_t ret;
    if (ts_state != TS_READY)
      return EBUSY;

    ts_state = TS_BUSY;
    ret = call Hpl.readRaw(&raw_data);

    if (ret == SUCCESS)
      coord_ptr = xy;
    
    return ret;
  }

  event void Hpl.rawDataReady()
  {
    calculate_coordinates();
    ts_state = TS_READY;
    signal TouchScreen.coordinatesReady();
  }

  command error_t Init.init()
  {
    error_t ret = call Hpl.init();
    ts_state = TS_READY;
    offset_x = 0;
    offset_y = 0;
    return ret;
  }

  /************* PRIVATE *************/

  void calculate_coordinates(void)
  {
      uint8_t temp;

      if (raw_data.x <= TS_RAW_X_MIN){
	temp = 0;
      } else {
	temp = (raw_data.x - TS_RAW_X_MIN);
      }

      temp = (((uint32_t)raw_data.x)*128)/(TS_RAW_X_MAX-TS_RAW_X_MIN);
      if ((int16_t)(temp + offset_x) < 0){
	temp = 0;
      } else {	
	temp += offset_x;
      }
      if (temp > 127)
	temp = 127;

      memcpy(&coord_ptr->x, &temp, sizeof(temp));

      if (raw_data.y <= TS_RAW_Y_MIN){
	temp = 0;
      } else {
	temp = (raw_data.y - TS_RAW_Y_MIN);
      }
      temp = (((uint32_t)raw_data.y)*64)/(TS_RAW_Y_MAX-TS_RAW_Y_MIN);
      if ((int16_t)(temp + offset_y) < 0){
	temp = 0;
      } else {	
	temp += offset_y;
      }
      if (temp > 63)
	temp = 63;

      temp = 63-temp;
      memcpy(&coord_ptr->y, &temp, sizeof(temp));
  }
  
}

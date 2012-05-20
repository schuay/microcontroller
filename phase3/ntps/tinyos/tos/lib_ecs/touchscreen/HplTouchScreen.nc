/**
 * Hpl interface for TouchScreen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      13.02.2012
 */

#include "HplTouchScreen.h"

interface HplTouchScreen
{
    /**
   * Initialize Touch Screen
   * 
   * @return SUCCESS
   */
  command error_t init(void);

  /**
   * Request read of raw data from touchscreen
   * 
   * @param Pointer to a buffer where the data will be stored
   *
   * @return SUCCESS if request is accepted
   *         EBUSY if another request is pending
   *         FAIL on other error
   */
  command error_t readRaw(touchscreen_raw_t *raw_data);
  
  /**
   * Notification that raw data is ready
   */
  event void rawDataReady(void);
}

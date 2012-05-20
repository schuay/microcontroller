/**
 * Interface for TouchScreen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      13.02.2012
 */

#include "TouchScreen.h"

interface TouchScreen
{

  /**
   *
   * @param x_offset
   * @param y_offset
   *
   * @return SUCCESS
   */
  command error_t calibrate(int8_t x_offset, int8_t y_offset);

  /**
   *
   * @param pointer to buffer for coordinates
   *
   * @return SUCCESS if request was accepted
   *           EBUSY if another request is pending
   */
  command error_t getCoordinates( ts_coordinates_t *xy );

  /**
   * Notification that coordinates are ready
   *
   */
  event void coordinatesReady(void);
}

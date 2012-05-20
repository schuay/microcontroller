/**
 * Hpl interface for KS0108 GLCD Display
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 */

interface HplKS0108
{

  /**
   * Initialize GLCD
   * 
   * @return SUCCESS
   */
  command error_t init(void); 

  /**
   * Read controller state
   *
   * @param The controller to be checked
   * 
   * @return state of the controller
   *
   */
  command uint8_t controlRead(const uint8_t controller);

  /**
   * Write to controller
   *
   * @param The controller to write to
   * @param controller data
   * 
   * @return SUCCESS
   *
   */
  command error_t controlWrite(const uint8_t controller, const uint8_t data);
  
  /**
   * Read data
   *
   * @param The controller to be read from
   * 
   * @return data
   *
   */
  command uint8_t dataRead(const uint8_t controller);

  /**
   * Write data
   *
   * @param The controller to write to
   * @param data
   * 
   * @return SUCCESS
   *
   */
  command error_t dataWrite(const uint8_t controller, const uint8_t data);
}

/**
 * High level interface for KS0108 GLCD Display
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 */

#include "KS0108.h"

interface Glcd
{
  
  /**
   * Set pixel
   *
   * @param x-coordinate
   * @param y-coordinate
   * 
   * @return SUCCESS
   *
   */
  command error_t setPixel(const uint8_t x, const uint8_t y);

  /**
   * Clear pixel
   *
   * @param x-coordinate
   * @param y-coordinate
   * 
   * @return SUCCESS
   *
   */
  command error_t clearPixel(const uint8_t x, const uint8_t y);

  /**
   * Invert pixel
   *
   * @param x-coordinate
   * @param y-coordinate
   * 
   * @return SUCCESS
   *
   */
  command error_t invertPixel(const uint8_t x, const uint8_t y);

  /**
   * Draw line
   *
   * @param first point x
   * @param first point y
   * @param second point x
   * @param second point y
   * 
   * @return SUCCESS
   *
   */
  command error_t drawLine(const uint8_t x1, const uint8_t y1,
			   const uint8_t x2, const uint8_t y2);

  /**
   * Draw rectangle
   *
   * @param upper left x
   * @param upper left y
   * @param lower right x
   * @param lower right y
   * 
   * @return SUCCESS
   *
   */
  command error_t drawRect(const uint8_t x1,const uint8_t y1,
			   const uint8_t x2,const uint8_t y2);

  /**
   * Draw ellipse
   *
   * @param center x
   * @param center y
   * @param radius horizontal
   * @param radius vertical
   * 
   * @return SUCCESS
   *
   */
  command error_t drawEllipse(const uint8_t x, const uint8_t y,
			      const uint8_t radius_h, const uint8_t radius_v);

  /**
   * Fill Display with pattern
   *
   * @param pattern
   * 
   * @return SUCCESS
   *
   */
  command error_t fill(uint8_t pattern);

  /**
   * drawText
   *
   * @param text
   * @param x-coordinate of lower left edge
   * @param y-coordinate of lower left edge
   * 
   * @return SUCCESS
   *
   */
  command void drawText(const char *text, const uint8_t x, const uint8_t y);
  
}

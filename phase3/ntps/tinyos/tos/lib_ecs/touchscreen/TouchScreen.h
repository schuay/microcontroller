/**
 * Hpl interface for TouchScreen
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      14.02.2012
 */

#ifndef TOUCHSCREEN_H
#define TOUCHSCREEN_H

#define TS_CALIB_MIN_X 500
#define TS_CALIB_MIN_Y 500

#define TS_CALIB_XA 16
#define TS_CALIB_YA 16

#define TS_CALIB_XB 108
#define TS_CALIB_YB 108

#define TS_CALIB_RAD 6

#define TS_RAW_X_MIN 0
#define TS_RAW_X_MAX 826
#define TS_RAW_Y_MIN 14
#define TS_RAW_Y_MAX 728


typedef struct{
  uint8_t x;
  uint8_t y;
} ts_coordinates_t;

#endif

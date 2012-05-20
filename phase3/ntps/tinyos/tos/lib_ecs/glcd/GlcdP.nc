/**
 * High level implementation for KS0108 Glcd
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 * Based on an implementation of Andreas Hagmann
 */

/*

   Pages:
   01234567
  |--------| 
  |        | 
  | Ctrl0  |  X-pos 
  |        |  |
  |--------|  |
  |        |  |
  | Ctrl1  |  |-----Y-page
  |        |
  |--------|

*/

#include "KS0108.h"
#include "Standard5x7.h"

/**************** INTERNAL DEFINITIONS ****************/
#define KS0108_SET_PAGE              (0xB8)    // 10111XXX: set lcd page (X) address
#define KS0108_SET_ADDR              (0x40)    // 01YYYYYY: set lcd Y address
#define KS0108_XPIXELS               (128)
#define KS0108_CONTROLLER_XPIXELS    (64)
#define KS0108_YPAGES                (8)

/** Number of spaces that tabs (\t) is replaced with. */
#define TAB_WIDTH               (2)

typedef struct xy_point_signed_t{
  int16_t x, y;
} xy_point_signed;

module GlcdP
{
  provides interface Glcd;
  provides interface Init;
  uses interface HplKS0108 as Hpl;
}

implementation {
  /************* PROTOTYPES **********/
  void setAddress(const uint8_t x_pos, const uint8_t y_page);
  void plot4points(const xy_point c, const uint8_t x, const uint8_t y);
  void drawChar(const char c, const xy_point p, const font* f);
  
  command error_t Init.init()
  {
    error_t ret = call Hpl.init();
    return ret;
  }

  command error_t Glcd.setPixel(const uint8_t x, const uint8_t y)
  {
    uint8_t data;
    uint8_t x_pos = x;
    /* y_page = y/8 */
    uint8_t y_page = (y>>3);
    uint8_t controller = ((x >> 6) & 0x01);
    controller ^= 1;

    setAddress(x_pos, y_page);
    data = call Hpl.dataRead(controller);
    data |= (1 << (y & 7));
    setAddress(x_pos, y_page);
    call Hpl.dataWrite(controller, data);
    
    return SUCCESS;
  } /* END setPixel */

  command error_t Glcd.clearPixel(const uint8_t x, const uint8_t y)
  {
    uint8_t data;
    uint8_t x_pos = x;
    /* y_page = y/8 */
    uint8_t y_page = (y>>3);
    uint8_t controller = ((x >> 6) & 0x01);
    controller ^= 1;

    setAddress(x_pos, y_page);
    data = call Hpl.dataRead(controller);
    data &= ~(1 << (y & 7));
    setAddress(x_pos, y_page);
    call Hpl.dataWrite(controller, data);
      
    return SUCCESS;
  } /* END clearPixel */

  command error_t Glcd.invertPixel(const uint8_t x, const uint8_t y)
  {
    uint8_t data;
    uint8_t x_pos = x;
    /* y_page = y/8 */
    uint8_t y_page = (y>>3);
    uint8_t controller = ((x >> 6) & 0x01);
    controller ^= 1;

    setAddress(x_pos, y_page);
    data = call Hpl.dataRead(controller);
    data ^= (1 << (y & 7));
    setAddress(x_pos, y_page);
    call Hpl.dataWrite(controller, data);
    
    return SUCCESS;
  } /* END invertPixel */

  command error_t Glcd.fill(uint8_t pattern)
  {
    uint8_t x_pos;
    uint8_t y_page;
    
    for (y_page = 0; y_page < KS0108_YPAGES; y_page++){
      setAddress(0, y_page);
      setAddress(KS0108_CONTROLLER_XPIXELS, y_page);
      for (x_pos = 0; x_pos < KS0108_XPIXELS; x_pos++){
	call Hpl.dataWrite(0, pattern);
	call Hpl.dataWrite(1, pattern);
      }
    }
    return SUCCESS;
  } /* END fill */
  
  command error_t Glcd.drawLine(const uint8_t x1,const uint8_t y1,const uint8_t x2,const uint8_t y2)
  {
    xy_point p1;
    xy_point p2;

    int16_t err, e2; 
    xy_point_signed d, s;
    xy_point px;

    p1.x = x1;
    p1.y = y1;
    p2.x = x2;
    p2.y = y2;
    
    px.x = p1.x; px.y = p1.y;
    d.x = p2.x - p1.x;
    d.y = p2.y - p1.y;
    if(d.x < 0)
      d.x = -d.x;
    if(d.y < 0)
      d.y = -d.y;
    
    s.x = -1;
    if(p1.x < p2.x)
      s.x = 1;
    
    s.y = -1;
    if(p1.y < p2.y)
      s.y = 1;
    
    err = d.x - d.y;
 
    while(1){
      call Glcd.setPixel(px.x, px.y);
      
      if((px.x == p2.x) && (px.y == p2.y))
	break;
      
      e2 = err<<1;
      
      if(e2 > -d.y){
	err -= d.y;
	px.x += s.x;
      }
      if(e2 < d.x){
	err += d.x;
	px.y += s.y;
      }
    }
    return SUCCESS;
  } /* END drawLine */
  
  command error_t Glcd.drawRect(const uint8_t x1,const uint8_t y1,const uint8_t x2,const uint8_t y2)
  {
    uint8_t dx, dy, x;
    xy_point p1;
    xy_point p2;

    p1.x = x1;
    p1.y = y1;
    p2.x = x2;
    p2.y = y2;

    dx = (p2.x > p1.x ? 1 : -1);
    dy = (p2.y > p1.y ? 1 : -1);

    for(x = p1.y + dy; x != p2.y; x += dy){
      call Glcd.setPixel(p1.x, x);
      call Glcd.setPixel(p2.x, x);
    }
    
    x = p1.x;
    
    while(1){
      call Glcd.setPixel(x, p1.y);
      call Glcd.setPixel(x, p2.y);
      
      if(x == p2.x)
	break;
      
      x += dx;
    }
    return SUCCESS;
  } /* END drawRect */
  
  command error_t Glcd.drawEllipse(const uint8_t x, const uint8_t y, const uint8_t radius_h, const uint8_t radius_v)
  {
    int16_t sqRx, sqRy;
    xy_point p;
    xy_point c;
    int16_t  chgX, chgY;
    int16_t stopX, stopY, error;

    c.x = x;
    c.y = y;

    sqRx = radius_h * radius_h;
    sqRy = radius_v * radius_v;
    chgX = sqRy;
    chgY = sqRx;
    
    sqRx <<= 1;
    sqRy <<= 1;
    
    chgX *= (1 - (radius_h<<1));
    
    stopX = sqRy * radius_h;
    stopY = 0;
    
    p.x = radius_h;  p.y = 0;
    error = 0;
    
    while(stopX >= stopY){
      plot4points(c, p.x, p.y);
      
      ++p.y;
      stopY += sqRx;
      error += chgY;
      chgY  += sqRx;
      
      if(((error << 1) + chgX) > 0){
	--p.x;
	stopX -= sqRy;
	error += chgX;
	chgX  += sqRy;
      }
    }
    
    chgX = (sqRy>>1);
    chgY = (sqRx>>1) * (1 - (radius_v<<1));
    stopX = 0;
    stopY = sqRx * radius_v;
    
    p.x = 0;    p.y = radius_v;
    error = 0;
    
    while(stopX <= stopY){
      plot4points(c, p.x, p.y);
      
      ++p.x;
      stopX += sqRy;
      error += chgX;
      chgX  += sqRy;
      
      if(((error << 1) + chgY) > 0){
	--p.y;
	stopY -= sqRx;
	error += chgY;
	chgY  += sqRx;
      }
    }
    return SUCCESS;
  } /* END drawEllipse */
  
  command void Glcd.drawText(const char *text, const uint8_t x, const uint8_t y)
  {
    const font* f = &Standard5x7;
    xy_point p;
    xy_point px;
    p.x = x;
    p.y = y;
    px = p;

    for(; *text != 0; ++text){
      if((*text == '\n') || (*text == '\r')){
	px.x = p.x;
	px.y += f->lineSpacing;
	continue;
      }
      if(*text == '\t'){
	px.x += TAB_WIDTH * f->width;
	continue;
      }
      
      px.x += f->charSpacing;
      drawChar(*text, px, f);
    }
  } /* END drawText */
  
  /************* PRIVATE *************/
  
  void drawChar(const char c, const xy_point p, const font* f)
  {
    const uint8_t *cpointer = (f->font) + ((c - f->startChar) * (f->width));
    uint8_t cp, cv, i;
    xy_point px = p;
    
    if((c < f->startChar) || (c > f->endChar))
      return;
    
    for(cp = 0; cp < 5; ++cp){
      px.y = p.y - f->height;
      
      cv = pgm_read_byte(cpointer);
      
//      while(cv > 0){
	for(i=0; i<7;++i){
	if((cv & 1) != 0){
	  call Glcd.setPixel(px.x, px.y);
	} else {
	  call Glcd.clearPixel(px.x, px.y);
	}
	
	cv >>= 1;
	++px.y;
      }
      
      ++px.x;
      ++cpointer;
    }
  } /* END drawChar */

  void plot4points(const xy_point c, const uint8_t x, const uint8_t y)
  {
    call Glcd.setPixel(c.x + x, c.y + y);
    if(x != 0)
      call Glcd.setPixel(c.x - x, c.y + y);
    if(y != 0)
      call Glcd.setPixel(c.x + x, c.y - y);
    
    call Glcd.setPixel(c.x - x, c.y - y);
  } /* END plot4points */
  
  void setAddress(const uint8_t x_pos, const uint8_t y_page)
  {
    /* x < 64 write to controller 1 - else 0 */
    uint8_t controller = (x_pos >> 6);
    controller ^= 1;
    call Hpl.controlWrite(controller, KS0108_SET_ADDR|(x_pos & 0x3F));
    call Hpl.controlWrite(controller, KS0108_SET_PAGE|(y_page & 0x07));
  } /* END setAddress */
  
}

#ifndef __GLCD_FONT_DEFINITIONS__
#define __GLCD_FONT_DEFINITIONS__

#include <avr/pgmspace.h>

typedef struct font_t
{
    /** First character in font */
    uint8_t     startChar;
    
    /** Last character in font */
    uint8_t     endChar;
    
    /** Character width */
    uint8_t     width;
    
    /** Character height, limited to 8 pixel (uint8_t) */
    uint8_t     height;
    
    /** Character spacing (horizontal) */
    uint8_t     charSpacing;
    
    /** Line spacing (vertical) */
    uint8_t     lineSpacing;
    
    /** Characters in progmem */
    const uint8_t *font;
} font;

#endif


// $Id: atm128const.h,v 1.4 2006-12-12 18:23:03 vlahan Exp $

/* 
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * const_[u]int[8/16/32]_t types are used to declare single and array
 * constants that should live in ROM/FLASH. These constants must be read
 * via the corresponding read_[u]int[8/16/32]_t functions.
 * 
 * This file defines the ATmega128 version of these types and functions.
 * @author David Gay
 */

#ifndef ATMEGA128CONST_H
#define ATMEGA128CONST_H

#define GCC_VERSION (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)

#if GCC_VERSION < 40700
typedef uint8_t const_uint8_t PROGMEM;
typedef uint16_t const_uint16_t PROGMEM;
typedef uint32_t const_uint32_t PROGMEM;
typedef int8_t const_int8_t PROGMEM;
typedef int16_t const_int16_t PROGMEM;
typedef int32_t const_int32_t PROGMEM;
#else
typedef const uint8_t const_uint8_t PROGMEM;
typedef const uint16_t const_uint16_t PROGMEM;
typedef const uint32_t const_uint32_t PROGMEM;
typedef const int8_t const_int8_t PROGMEM;
typedef const int16_t const_int16_t PROGMEM;
typedef const int32_t const_int32_t PROGMEM;
#endif

#define read_uint8_t(x) pgm_read_byte(x)
#define read_uint16_t(x) pgm_read_word(x)
#define read_uint32_t(x) pgm_read_dword(x)

#define read_int8_t(x) ((int8_t)pgm_read_byte(x))
#define read_int16_t(x) ((int16_t)pgm_read_word(x))
#define read_int32_t(x) ((int32_t)pgm_read_dword(x))


#endif

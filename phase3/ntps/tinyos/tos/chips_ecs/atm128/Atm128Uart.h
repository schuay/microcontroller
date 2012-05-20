// $Id: Atm128Uart.h,v 1.6 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// @author Martin Turon <mturon@xbow.com>

/**
 * @author Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 */

#ifndef _H_Atm128Uart_h
#define _H_Atm128Uart_h

//====================== UART Bus ==================================

/* UART Status Register */
typedef union {
  struct Atm128_UCSRA_t {
    uint8_t mpcm : 1;  //!< UART Multiprocessor Communication Mode
    uint8_t u2x  : 1;  //!< UART Double Transmission Speed
    uint8_t upe  : 1;  //!< UART Parity Error
    uint8_t dor  : 1;  //!< UART Data Overrun
    uint8_t fe   : 1;  //!< UART Frame Error
    uint8_t udre : 1;  //!< USART Data Register Empty
    uint8_t txc  : 1;  //!< USART Transfer Complete
    uint8_t rxc  : 1;  //!< USART Receive Complete
  } bits;
  uint8_t flat;
} Atm128UartStatus_t;

/* UART Control Register */
typedef union {
  struct Atm128_UCSRB_t {
    uint8_t txb8  : 1;  //!< UART Transmit Data Bit 8
    uint8_t rxb8  : 1;  //!< UART Receive Data Bit 8
    uint8_t ucsz2 : 1;  //!< UART Character Size (Bit 2)
    uint8_t txen  : 1;  //!< UART Transmitter Enable
    uint8_t rxen  : 1;  //!< UART Receiver Enable
    uint8_t udrie : 1;  //!< USART Data Register Enable
    uint8_t txcie : 1;  //!< UART TX Complete Interrupt Enable
    uint8_t rxcie : 1;  //!< UART RX Complete Interrupt Enable
  } bits;
  uint8_t flat;
} Atm128UartControl_t;

enum {
  ATM128_UART_DATA_SIZE_5_BITS = 0,
  ATM128_UART_DATA_SIZE_6_BITS = 1,
  ATM128_UART_DATA_SIZE_7_BITS = 2,
  ATM128_UART_DATA_SIZE_8_BITS = 3,
};

/* UART Control Register */
typedef union {
  uint8_t flat;
  struct Atm128_UCSRC_t {
    uint8_t ucpol : 1;  //!< UART Clock Polarity
    uint8_t ucsz  : 2;  //!< UART Character Size (Bits 0 and 1)
    uint8_t usbs  : 1;  //!< UART Stop Bit Select
    uint8_t upm   : 2;  //!< UART Parity Mode
    uint8_t umsel : 1;  //!< USART Mode Select
    uint8_t rsvd  : 1;  //!< Reserved
  } bits;
} Atm128UartMode_t;

typedef enum {
  TOS_UART_PARITY_NONE = 0,
  TOS_UART_PARITY_EVEN = 1,
  TOS_UART_PARITY_ODD  = 2,
} uart_parity_t;

typedef enum {
  TOS_UART_9600   = 9600UL,
  TOS_UART_19200  = 19200UL,
  TOS_UART_38400  = 38400UL,
  TOS_UART_57600  = 57600UL,
  TOS_UART_115200 = 115200UL,
} uart_speed_t;

typedef enum {
  TOS_UART_OFF    = 0,
  TOS_UART_RONLY  = 1,
  TOS_UART_TONLY  = 2,
  TOS_UART_DUPLEX = 3,
} uart_duplex_t;

#endif //_H_Atm128UART_h


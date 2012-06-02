/*
 * Copyright (c) 2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCH ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Alec Woo <awoo@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Philip Levis <pal@cs.stanford.edu> (maintainer)
 * @version $Revision: 1.7 $ $Date: 2008-06-23 20:25:15 $
 *
 * Modification @ 11/27 (pal): Folded in Alec's reimplementation
 * from the -devel branch. Fixed bug in RX interrupts, where
 * they were not enabled on start. Possibly due to alternative
 * ARC TEP113 implementation that uses UartStream?
 */

#include <Timer.h>

generic module Atm128UartP() @safe() {

  provides interface StdControl;
  provides interface UartByte;
  provides interface UartStream;

  uses interface StdControl as HplUartTxControl;
  uses interface StdControl as HplUartRxControl;
  uses interface HplAtm128Uart as HplUart;
  uses interface Counter<TMicro, uint32_t>;

  uses interface UartControl;

}

implementation{

  norace uint16_t m_tx_len, m_rx_len;
  norace uint8_t *COUNT_NOK(m_tx_len) m_tx_buf, * COUNT_NOK(m_rx_len) m_rx_buf;
  norace uint16_t m_tx_pos, m_rx_pos;
  norace uint8_t m_rx_intr;
  norace uint8_t m_tx_intr;

  command error_t StdControl.start(){
    /* make sure interupts are off and set flags */
    call HplUart.disableTxIntr();
    call HplUart.disableRxIntr();
    m_rx_intr = 0;
    m_tx_intr = 0;

    /* enable tx/rx */
    call HplUartTxControl.start();
    call HplUartRxControl.start();

    // Bug fix: pal 11/26/07: RX interrupts should be enabled on start
    // Bug fix of the Bug fix: koe 05/31/12: previous bug fix breaks UartByte.receive
    //                         If you want to use UartStream enable receive interrupt by hand
    //call HplUart.enableRxIntr();
    return SUCCESS;
  }

  command error_t StdControl.stop(){
    call HplUartTxControl.stop();
    call HplUartRxControl.stop();
    return SUCCESS;
  }

  async command error_t UartStream.enableReceiveInterrupt(){
    atomic{
      m_rx_intr = 3;
      call HplUart.enableRxIntr();
    }
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt(){
    atomic{
      call HplUart.disableRxIntr();
      m_rx_intr = 0;
    }
    return SUCCESS;
  }

  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ){

    if ( len == 0 )
      return FAIL;
    atomic {
      if ( m_rx_buf )
	return EBUSY;
      m_rx_buf = buf;
      m_rx_len = len;
      m_rx_pos = 0;
      m_rx_intr |= 1;
      call HplUart.enableRxIntr();
    }

    return SUCCESS;

  }

  async event void HplUart.rxDone( uint8_t data ) {

    if ( m_rx_buf ) {
      m_rx_buf[ m_rx_pos++ ] = data;
      if ( m_rx_pos >= m_rx_len ) {
	uint8_t* buf = m_rx_buf;
	atomic{
	  m_rx_buf = NULL;
	  if(m_rx_intr != 3){
	    call HplUart.disableRxIntr();
	    m_rx_intr = 0;
	  }
	}
	signal UartStream.receiveDone( buf, m_rx_len, SUCCESS );
      }
    }
    else {
      signal UartStream.receivedByte( data );
    }

  }

  async command error_t UartStream.send( uint8_t *buf, uint16_t len){

    if ( len == 0 )
      return FAIL;
    else if ( m_tx_buf )
      return EBUSY;

    m_tx_len = len;
    m_tx_buf = buf;
    m_tx_pos = 0;
    m_tx_intr = 1;
    call HplUart.enableTxIntr();
    call HplUart.tx( buf[ m_tx_pos++ ] );

    return SUCCESS;

  }

  async event void HplUart.txDone() {

    if ( m_tx_pos < m_tx_len ) {
      call HplUart.tx( m_tx_buf[ m_tx_pos++ ] );
    }
    else {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      m_tx_intr = 0;
      call HplUart.disableTxIntr();
      signal UartStream.sendDone( buf, m_tx_len, SUCCESS );
    }

  }

  async command error_t UartByte.send( uint8_t byte ){
    if(m_tx_intr)
      return FAIL;

    call HplUart.tx( byte );
    while ( !call HplUart.isTxEmpty() );
    return SUCCESS;
  }

  async command error_t UartByte.receive( uint8_t * byte, uint8_t timeout){

    uint32_t timeout_micro;
    uint32_t start;

    uint16_t magic;


    switch(call UartControl.speed()){
      case TOS_UART_9600:
        /* 1000000/9600=104.16 us/Bit -> 1042us per byte   */
        /* (for simplicity we assume 8N1 -> 10Bit)         */
        magic=1042;
      break;
      case TOS_UART_19200:
        /* 1000000/19200=52.08 us/Bit -> 521us per byte    */
        magic=521;
      break;
      case TOS_UART_38400:
        /* 1000000/38400=26.04 us/Bit -> 260us per byte    */
        magic=260;
      break;
      case TOS_UART_57600:
        /* 1000000/57600=17.36 us/Bit -> 174us per byte    */
        magic=260;
      break;
      case TOS_UART_115200:
        /* 1000000/115200=8.68 us/Bit -> 87us per byte     */
        magic=260;
      break;
      default:
        /* unsupported Baudrate, assume 500us per byte     */
        magic=500;
    }

    if(m_rx_intr)
      return FAIL;

    start = call Counter.get();
    timeout_micro = timeout * magic;

    while ( call HplUart.isRxEmpty() ) {
      if ( ( call Counter.get() - start ) >= timeout_micro )
	return FAIL;
    }
    *byte = call HplUart.rx();

    return SUCCESS;
  }

  async event void Counter.overflow() {}

  default async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ){}
  default async event void UartStream.receivedByte( uint8_t byte ){}
  default async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ){}

}

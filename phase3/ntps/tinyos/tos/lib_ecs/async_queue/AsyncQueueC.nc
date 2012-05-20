/* $Id: QueueC.nc,v 1.7 2009-06-25 18:37:24 scipio Exp $ */
/*
 * Copyright (c) 2006 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *  A general FIFO queue component, whose queue has a bounded size.
 *
 *  @author Philip Levis
 *  @author Geoffrey Mainland
 *  @author Andreas Hagmann (add async keywords)
 *  @date   $Date: 2009-06-25 18:37:24 $
 */

   
generic module AsyncQueueC(typedef queue_t, uint8_t QUEUE_SIZE) {
  provides interface AsyncQueue<queue_t>;
}

implementation {

  queue_t ONE_NOK queue[QUEUE_SIZE];
  uint8_t head = 0;
  uint8_t tail = 0;
  uint8_t size = 0;
  
  async command bool AsyncQueue.empty() {
    return size == 0;
  }

  async command uint8_t AsyncQueue.size() {
    return size;
  }

  async command uint8_t AsyncQueue.maxSize() {
    return QUEUE_SIZE;
  }

  async command queue_t AsyncQueue.head() {
    return queue[head];
  }
  
  async command queue_t AsyncQueue.dequeue() {
    queue_t t = call AsyncQueue.head();
    dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
    if (!call AsyncQueue.empty()) {
      head++;
      if (head == QUEUE_SIZE) head = 0;
      size--;
    }
    return t;
  }

  async command error_t AsyncQueue.enqueue(queue_t newVal) {
    if (call AsyncQueue.size() < call AsyncQueue.maxSize()) {
      queue[tail] = newVal;
      tail++;
      if (tail == QUEUE_SIZE) tail = 0;
      size++;
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  async command queue_t AsyncQueue.element(uint8_t idx) {
    idx += head;
    if (idx >= QUEUE_SIZE) {
      idx -= QUEUE_SIZE;
    }
    return queue[idx];
  }  

}

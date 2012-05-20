// $Id: Atm128AlarmSyncP.nc,v 1.8 2008-06-26 03:38:27 regehr Exp $
/*
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Build a 32-bit alarm and counter from the atmega128's 8-bit timer 0
 * in asynchronous mode. Attempting to use the generic Atm128AlarmC
 * component and the generic timer components runs into problems
 * apparently related to letting timer 0 overflow.
 * 
 * So, instead, this version (inspired by the 1.x code and a remark from
 * Martin Turon) directly builds a 32-bit alarm and counter on top of timer 2
 * and never lets timer 2 overflow.
 *
 * Based on Atm1281AlarmAsyncP
 *
 * @author David Gay
 * @author Markus Hartmann <e9808811@student.tuwien.ac.at>
 */

/*

	GLOBAL: *Async* --> *Sync*
	
*/

generic module Atm1280AlarmSyncP(typedef precision, int divider) @safe() {
  provides {
    interface Init;
    interface Alarm<precision, uint32_t>;
    interface Counter<precision, uint32_t>;
  }
  uses {
    interface HplAtm128Timer<uint8_t> as Timer;
    interface HplAtm128TimerCtrl8 as TimerCtrl;
    interface HplAtm128Compare<uint8_t> as Compare;
    interface HplAtm128TimerSync as TimerSync;
  }
}
implementation
{
  uint8_t set; 			/* Is the alarm set? */
  uint32_t t0, dt;		/* Time of the next alarm */
  norace uint32_t base;		/* base+TCNT0 is the current time if no
				   interrupt is pending. See Counter.get()
				   for the full details. */

  enum {
    MINDT = 2,			/* Minimum interval between interrupts */
    MAXT = 230			/* Maximum value to let timer 0 reach
				   (from Joe Polastre and Robert Szewczyk's
				   painful experiences with the 1.x timer ;-)) */
  };

  void setInterrupt();

  /* Configure timer 2 */
  command error_t Init.init() {
    atomic
      {
	/*Atm128TimerControl_t x;*/
	Atm128_TCCR2A_t x;
	Atm128_TCCR2B_t y;

	call TimerSync.setTimer2Synchronous();
	x.flat = 0;
	x.bits.wgm21 = 1; /* We use the clear-on-compare mode */
	call TimerCtrl.setControlA(x.flat);
	y.flat = 0;
	y.bits.cs = divider;
	call TimerCtrl.setControlB(y.flat);
	//x.flat = 0;
	//x.bits.cs = divider;
	//x.bits.wgm1 = 1; /* We use the clear-on-compare mode */
	call Compare.set(MAXT); /* setInterrupt needs a valid value here */
	call Compare.start();
      }
    setInterrupt();
    return SUCCESS;
  }

  /* Set compare register for timer 2 to n. But increment n by 1 if TCNT2
     reaches this value before we can set the compare register.
  */
  void setOcr2A(uint8_t n) {
    while (call TimerSync.compareABusy())
      ;
    if (n == call Timer.get())
      n++;
    /* Support for overflow. Force interrupt at wrap around value. 
       This does not cause a backwards-in-time value as we do this
       every time we set OCR0. */
    if (base + n + 1 < base)
      n = -base - 1;
    call Compare.set(n);
  }

  /* Update the compare register to trigger an interrupt at the
     appropriate time based on the current alarm settings
   */
  void setInterrupt() {
    bool fired = FALSE;

    atomic
      {
	/* interrupt_in is the time to the next interrupt. Note that
	   compare register values are off by 1 (i.e., if you set OCR2A to
	   3, the interrupt will happen whjen TCNT2 is 4) */
	uint8_t interrupt_in = 1 + call Compare.get() - call Timer.get();
	uint8_t newOcr2A;
	uint8_t tifr2 = call TimerCtrl.getInterruptFlag();
	dbg("Atm128AlarmSyncP", "Atm128AlarmSyncP: TIFR is %hhx\n", tifr2);
	if ((interrupt_in != 0 && interrupt_in < MINDT) || (tifr2 & (1 << OCF2A))) {
	  if (interrupt_in < MINDT) {
	    dbg("Atm128AlarmSyncP", "Atm128AlarmSyncP: under min: %hhu.\n", interrupt_in);
	  }
	  else {
	    dbg("Atm128AlarmSyncP", "Atm128AlarmSyncP: OCF2A set.\n");
	  }
	  return; // wait for next interrupt
	}

	/* When no alarm is set, we just ask for an interrupt every MAXT */
	if (!set) {
	  newOcr2A = MAXT;
	  dbg("Atm128AlarmSyncP", "Atm128AlarmSyncP: no alarm set, set at max.\n");
	}
	else
	  {
	    uint32_t now = call Counter.get();
	    dbg("Atm128AlarmSyncP", "Atm128AlarmSyncP: now-t0 = %llu, dt = %llu\n", (now-t0), dt);
	    /* Check if alarm expired */
	    if ((uint32_t)(now - t0) >= dt)
	      {
		set = FALSE;
		fired = TRUE;
		newOcr2A = MAXT;
	      }
	    else
	      {
		/* No. Set compare register to time of next alarm if it's
		   within the next MAXT units */
		uint32_t alarm_in = (t0 + dt) - base;

		if (alarm_in > MAXT)
		  newOcr2A = MAXT;
		else if ((uint8_t)alarm_in < MINDT) // alarm_in < MAXT ...
		  newOcr2A = MINDT;
		else
		  newOcr2A = alarm_in;
	      }
	  }
	newOcr2A--; // interrupt is 1ms late
	setOcr2A(newOcr2A);
      }
    if (fired)
      signal Alarm.fired();
  }

  async event void Compare.fired() {
    int overflowed;

    /* Compare register fired. Update time knowledge */
    base += call Compare.get() + 1U; // interrupt is 1ms late
    overflowed = !base;
    __nesc_enable_interrupt();
    setInterrupt();
    if (overflowed)
      signal Counter.overflow();
  }  

  async command uint32_t Counter.get() {
    uint32_t now;

    atomic
      {
	/* Current time is base+TCNT0 if no interrupt is pending. But if
	   an interrupt is pending, then it's base + compare value + 1 + TCNT0 */
	uint8_t now8 = call Timer.get();

	if ((((Atm128_TIFR2_t)call TimerCtrl.getInterruptFlag())).bits.ocfa)
	  /* We need to reread TCNT2 as it might've overflowed after we
	     read TCNT2 the first time */
	  now = base + call Compare.get() + 1 + call Timer.get();
	else
	  /* We need to use the value of TCNT2 from before we check the
	     interrupt flag, as it might wrap around after the check */
	  now = base + now8;
      }
    return now;
  }

  async command bool Counter.isOverflowPending() {
    atomic
      return (((Atm128_TIFR2_t)call TimerCtrl.getInterruptFlag())).bits.ocfa &&
	!(base + call Compare.get() + 1);
  }

  async command void Counter.clearOverflow() { 
    atomic
      if (call Counter.isOverflowPending())
	{
	  base = 0;
	  call Compare.reset();
	}
      else
	return;
    setInterrupt();
  }

  async command void Alarm.start(uint32_t ndt) {
    call Alarm.startAt(call Counter.get(), ndt);
  }

  async command void Alarm.stop() {
    atomic set = FALSE;
  }

  async command bool Alarm.isRunning() {
    atomic return set;
  }

  async command void Alarm.startAt(uint32_t nt0, uint32_t ndt) {
    atomic
      {
	set = TRUE;
	t0 = nt0;
	dt = ndt;
      }
    setInterrupt();
  }

  async command uint32_t Alarm.getNow() {
    return call Counter.get();
  }

  async command uint32_t Alarm.getAlarm() {
    atomic return t0 + dt;
  }

  async event void Timer.overflow() { }
}

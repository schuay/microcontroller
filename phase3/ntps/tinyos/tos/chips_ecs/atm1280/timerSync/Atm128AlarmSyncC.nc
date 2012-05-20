// $Id: Atm128AlarmAsyncC.nc,v 1.3 2007-05-23 22:49:08 idgay Exp $
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
 * Martin Turon) directly builds a 32-bit alarm and counter on top of timer 0
 * and never lets timer 0 overflow.
 *
 * @author David Gay
 * @author Markus Hartmann
 */

/*

	GLOBAL: changed *Async* --> *Sync*
	changed 128 -> 1280

*/

generic configuration Atm128AlarmSyncC(typedef precision, int divider) {
  provides {
    interface Init @atleastonce();
    interface Alarm<precision, uint32_t>;
    interface Counter<precision, uint32_t>;
  }
}
implementation
{
  components new Atm1280AlarmSyncP(precision, divider),
    HplAtm1280Timer2SyncC;

  Init = Atm1280AlarmSyncP;
  Alarm = Atm1280AlarmSyncP;
  Counter = Atm1280AlarmSyncP;

  Atm1280AlarmSyncP.Timer -> HplAtm1280Timer2SyncC;
  Atm1280AlarmSyncP.TimerCtrl -> HplAtm1280Timer2SyncC;
  Atm1280AlarmSyncP.Compare -> HplAtm1280Timer2SyncC;
  Atm1280AlarmSyncP.TimerSync -> HplAtm1280Timer2SyncC;
}

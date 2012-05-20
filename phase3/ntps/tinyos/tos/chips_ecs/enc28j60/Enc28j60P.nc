/**
 * @author:	Harald Glanzer, 0727156 TU Wien
 *
 * overhauled by Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 */

#include "enc28j60.h"

module Enc28j60P {
	provides interface Mac;
	uses interface GeneralIO as ssETH;
	uses interface GeneralIO as rstETH;
	uses interface HplAtm128Interrupt as intETH;
	uses interface SpiByte;
	uses interface Resource;
	provides interface SplitControl;
	provides interface Enc28j60Control;
}

implementation {
	mac_addr_t myMac = { .bytes {MAC0, MAC1, MAC2,  MAC3, MAC4, MAC5}};
	uint8_t rcvBuffer[MAX_ETHERNET_PACKET_LEN];
	ethernet_state_t state = ETH_UNINIT;
	uint8_t *TXdataPtr;
	uint16_t TXlen;
	uint16_t nextPacketPtr = RXSTART_INIT;
	mac_addr_t *TXdstMAC;

	bool doTx = FALSE;
	bool doRx = FALSE;
	bool intReq = FALSE;

	inline void writeSPI(uint8_t opAddr, uint8_t data) {
		call ssETH.clr();
		call SpiByte.write(opAddr);
		call SpiByte.write(data);
		call ssETH.set();
	}

	inline uint8_t readSPI(uint8_t opAddr) {
		uint8_t ret;
		call ssETH.clr();
		call SpiByte.write(opAddr);
		ret = call SpiByte.write(0);
		call ssETH.set();

		return ret;
	}

	void writeReg(uint8_t addr, uint8_t data) {
		writeSPI(ENC28J60_WRITE_CTRL_REG | addr, data);
	}

	inline void writeReg16(uint8_t addr, uint16_t data) {
		writeReg(addr, data&0xff);
		writeReg(addr+1, data>>8);
	}

	uint8_t readReg(uint8_t addr) {
		return readSPI(ENC28J60_READ_CTRL_REG | addr);
	}

	uint8_t readRegM(uint8_t addr) {
		uint8_t data;

		call ssETH.clr();
		call SpiByte.write(ENC28J60_READ_CTRL_REG | addr);
		call SpiByte.write(0xff);
		data = call SpiByte.write(0xff);
		call ssETH.set();
		return data;
	}

	void setBit(uint8_t addr, uint8_t bit) {
		call ssETH.clr();
		call SpiByte.write((ENC28J60_BIT_FIELD_SET | addr));
		call SpiByte.write(bit);
		call ssETH.set();
	}

	void clearBit(uint8_t addr, uint8_t bit) {
		call ssETH.clr();
		call SpiByte.write((ENC28J60_BIT_FIELD_CLR | addr));
		call SpiByte.write(bit);
		call ssETH.set();
	}

	// set registerbank: 0...3
	void setBank(uint8_t bank) {
		clearBit(ECON1, BSEL1 | BSEL0);
		setBit(ECON1, bank);
	}

	uint16_t readPhy(uint8_t addr) {
		uint16_t data;

		setBank(0x02);
		writeReg(MIREGADR, addr);
		writeReg(MICMD, MIIRD);

		setBank(0x03);
		do {
			data = readRegM(MISTAT);
		} while((data & ENBUSY) == 1);

		setBank(0x02);
		writeReg(MICMD, 0x00);

		data = readRegM(MIRDL);
		data |= readRegM(MIRDH) << 8;

		return data;
	}

	command mac_addr_t* Mac.getMac() {
		return &(myMac);
	}

	command error_t SplitControl.start() {
		volatile uint16_t counter;

		if (state == ETH_UNINIT) {
			call ssETH.makeOutput();
			call ssETH.set();
			call rstETH.makeOutput();

			call rstETH.clr();
			// low-active reset
			for (counter=0; counter<20000; counter++) {}
			call rstETH.set();
			for (counter=0; counter<20000; counter++) {}

			call intETH.clear();
			call intETH.edge(FALSE);
			call intETH.enable();

			if (call Resource.request() != SUCCESS) {
				return FAIL;
			}
			else {
				state = ETH_INITIALIZING;
				return SUCCESS;
			}
		}
		else {
			return EALREADY;
		}
	}

	command uint8_t Mac.send(mac_packet_t *packet, uint16_t len) {
		if(doTx == FALSE && state == ETH_READY) {
			if (call Resource.request() != SUCCESS) {
				return ERETRY;
			}
			else {
				TXdataPtr = (uint8_t*)packet;
				TXlen = len;
				doTx = TRUE;
				return SUCCESS;
			}
		}
		else {
			return EBUSY;
		}
	}

	command error_t SplitControl.stop() {
		// not supported
		return FAIL;
	}

	default event void Enc28j60Control.linkChange(link_status_t status) {

	}

	task void checkInterruptflag() {
		intReq = TRUE;
		call Resource.request();
	}

	event void Resource.granted(void) {
		uint8_t rc;
		uint16_t count, frameLen;
		bool tooLong = FALSE;
		uint8_t flags;
		uint8_t packetsPending = 0;

		call ssETH.set();			// start with HIGH-level

		switch (state) {
		case ETH_INITIALIZING:
			writeSPI(ENC28J60_SOFT_RESET, ENC28J60_SOFT_RESET);		// soft reset
			while((readReg(ESTAT) & CLKRDY) == 0);					// wait for oscillcator timer to expire - about 300us

			// PHY is ready... go on
			//	BANK0 - STUFF
			setBank(0);
			// set RX/TX - buffer. we have 8kb RAM for rx AND tx, ~1500byte for TX(1 MTU-frame), rest for RX
			writeReg16(ERXSTL, RXSTART_INIT);						//set START-adress for RX
			nextPacketPtr = RXSTART_INIT;
			writeReg16(ERXRDPTL, RXSTART_INIT);						//set ERXRDPT with same values as ERXST, as suggested in datasheet, 6.1
			writeReg16(ERXNDL, RXSTOP_INIT);						//set END-adress for RX
			writeReg16(ETXSTL, TXSTART_INIT);						//set START-adress for TX
			writeReg(ECON2, AUTOINC);								// set Autoincrement for Read/Write-buffer

			// BANK1 - STUFF
			setBank(1);
			writeReg(ERXFCON, UCEN | CRCEN | BCEN);					// enable unicast-, broadcast- and CRC-filter

			// BANK2 - STUFF
			setBank(2);
			writeReg(MACON2, 0);									// pull MAC out of reset
			writeReg(MACON1, MARXEN);								// enable RX
			writeReg(MACON3, FULDPX | FRMLNEN | TXCRCEN | PADCFG0);	// full duplex, automatic padding + CRC, enable TX, framelen-checking
			writeReg(MACON4, 0);
			writeReg16(MAMXFLL, MAX_ETHERNET_PACKET_LEN);			// set maximum frame lengh
			writeReg(MABBIPG, 0x15);								// inter packet gap, recomended value

			// BANK3 - STUFF
			myMac.bytes.b6 = TOS_NODE_ID;
			myMac.bytes.b5 = TOS_NODE_ID>>8;
			setBank(0x03);
			writeReg(MAADR0, myMac.bytes.b6);
			writeReg(MAADR1, myMac.bytes.b5);
			writeReg(MAADR2, myMac.bytes.b4);
			writeReg(MAADR3, myMac.bytes.b3);
			writeReg(MAADR4, myMac.bytes.b2);
			writeReg(MAADR5, myMac.bytes.b1);

			setBank(0x02);
			// ledA & ledB
			writeReg(MIREGADR, PHLCON);
			writeReg16(MIWRL, (0x04<<4) | (0x01<<8));	// link status

			// set linkchange - interrupt
			writeReg(MIREGADR, PHIE);
			writeReg16(MIWRL, 0x12);

			writeReg(EIE, INTIE | PKTIE | LINKIE);					// enable receive packet pending, linkchange and global-interrupt
			setBit(ECON1, ERXEN);									// enable RX

			state = ETH_READY;
			signal SplitControl.startDone(SUCCESS);
			break;

		case ETH_READY:
			if (intReq) {
				intReq = FALSE;
				flags =  readReg(EIR);

				//printf("if: %x\n", flags);

				if (flags & LINKIF) {								// link change
					rc = readPhy(PHIR);								// clear interrupt flag

					if ((rc & 0x04) != 0) {
						signal Enc28j60Control.linkChange(LINK_UP);
					}
					else {
						signal Enc28j60Control.linkChange(LINK_DOWN);
					}
				}

				setBank(1);
				packetsPending = readReg(EPKTCNT);

				if (packetsPending > 0) {
					//if (packetsPending > 1) printf("%d pending\n", packetsPending);
					doRx = TRUE;
				}

				if (flags & RXERIF) {								// receive error
					clearBit(EIR, RXERIF);							// clear interrupt flag
					debug("receive error, %d pending\n", packetsPending);
				}
			}

			if (doTx == TRUE) {
				setBank(0x00);
				writeReg16(EWRPTL, TXSTART_INIT);					// set START-adress for WR-Pointer = TX-Buffer-Start
				writeSPI((ENC28J60_WRITE_BUF_MEM), 0x00);			// write per-packet-control-byte - nothing to override.

				for(count = 0; count < TXlen; count++) {
					writeSPI((ENC28J60_WRITE_BUF_MEM), TXdataPtr[count]);
				}

				writeReg16(ETXNDL, TXlen);							// set length
				setBit(ECON1, TXRTS);								// START transmission!
				doTx = FALSE;
				signal Mac.sendDone(SUCCESS);
			}

			if (doRx == TRUE) {
				setBank(0x00);

				// working through the buffer memory. we use AUTOINC, we don't need to update the read-pointer
				// set READ - pointer to correct start-adress
				writeReg16(ERDPTL, nextPacketPtr);

				// read next packet pointer
				nextPacketPtr  = (uint16_t)readSPI(ENC28J60_READ_BUF_MEM);
				nextPacketPtr |= (uint16_t)readSPI(ENC28J60_READ_BUF_MEM) << 8;

				// read length of data
				frameLen = readSPI(ENC28J60_READ_BUF_MEM);
				frameLen |= (uint16_t)readSPI(ENC28J60_READ_BUF_MEM);

				// rest receive status
				readSPI(ENC28J60_READ_BUF_MEM);
				readSPI(ENC28J60_READ_BUF_MEM);

				if (frameLen < MAX_ETHERNET_PACKET_LEN && frameLen > sizeof(mac_header_t)) {
					for(count = 0; count < frameLen; count++) {
						rcvBuffer[count] = readSPI(ENC28J60_READ_BUF_MEM);
					}
				}
				else {
					tooLong = TRUE;
				}

				writeReg16(ERXRDPTL, nextPacketPtr);		// free buffer
				setBit(ECON2, PKTDEC);						// decrement pending packet count

				doRx = FALSE;

				if (tooLong == FALSE) {
					signal Mac.received((mac_packet_t*)&rcvBuffer);
				}
			}

			break;

		default:
			break;
		}

		call Resource.release();

		atomic {
			if (call intETH.getValue() == FALSE) {
				post checkInterruptflag();
			}
		}
	}

	async event void intETH.fired() {
		post checkInterruptflag();
	}
}

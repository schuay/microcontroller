/**
 * @author:	Christian Mauser, 0625688 and Alexander Heinisch, 0627820 (TU Wien)
 *
 */
#include <string.h>

// todo: remove warnings
// todo: turnoff tranceiver, instead of only the interrupt
// todo: store only pointers to config stuff ???

#include <avr/pgmspace.h>
#include <avr/io.h>
#include <avr/interrupt.h>

#include "mrf24w.h"
#include "wlan.h"

module Mrf24wP {
	provides interface Mac;
	provides interface WlanControl;
	uses interface GeneralIO as SlaveSelect;
	uses interface GeneralIO as resetPin;
	uses interface HplAtm128Interrupt as intWLAN;

	uses interface SpiByte;
	uses interface Resource;
	provides interface SplitControl;
}

implementation {
	typedef enum {
		RESOURCE_START,
		RESOURCE_DRIVE,
	} resource_state_t;

	void chipStop(void);
	void spi_transfer(volatile uint8_t* locBuf, uint16_t len, uint8_t toggle_cs);
	void chip_reset(void);
	void interrupt_reg(uint8_t mask, uint8_t state);
	error_t process_isr(void);
	void send(uint8_t* locBuf, uint16_t len);
	error_t recv(uint8_t *buf);
	void set_sec(uint8_t sec_type, uint8_t* sec_key, uint8_t sec_key_len);
	void drv_process(void);
	task void isr(void);

	mac_addr_t  mac;

	uint8_t ssid[MAX_SSID_LEN];
	uint8_t passphrase[MAX_PASSPHRASE_LEN];
	security_type_t securityType = SECURITY_TYPE_NONE;
	wireless_mode_t wirelessMode = WIRELESS_MODE_INFRA;

	uint8_t hdr[5];
	uint8_t buf[MAC_MAX_PACKET_LEN+2];		// todo: check if length is OK

	resource_state_t resourceState;

	static uint8_t  wpa_psk_key[32];

	void spi_transfer(volatile uint8_t* locBuf, uint16_t len, uint8_t toggle_cs) {
		uint16_t i;

		call SlaveSelect.clr();
		for (i = 0; i < len; i++) {
			locBuf[i] = call SpiByte.write(locBuf[i]);
		}

		if (toggle_cs) {
			call SlaveSelect.set();
		}
	}

	void writeSpiReg(uint8_t addr, uint16_t data) {
		spi_reg_transfer_t t;

		t.addr = addr;
		t.data = data;

		spi_transfer((uint8_t*)&t, sizeof(t), 1);
	}

	uint16_t readSpiReg(uint8_t addr) {
		spi_reg_transfer_t t;

		t.addr = 0x40 | addr;
		t.data = 0;

		spi_transfer((uint8_t*)&t, sizeof(t), 1);

		return t.data;
	}

	void chipStop() {
		call intWLAN.disable();
	}

	void chip_reset() {
		uint16_t regVal;
		uint16_t counter;

		// hardware reset
		call resetPin.makeOutput();
		call resetPin.clr();
		// low-active reset
		for (counter=0; counter<20000; counter++) {}
		call resetPin.set();
		for (counter=0; counter<20000; counter++) {}

		// software reset
		writeSpiReg(INDEX_ADDR_REG, RESET_REG);
		writeSpiReg(INDEX_DATA_REG, 0x80ff);

		writeSpiReg(INDEX_ADDR_REG, RESET_REG);
		writeSpiReg(INDEX_DATA_REG, 0x0fff);

		// write reset register data
		writeSpiReg(INDEX_ADDR_REG, RESET_STATUS_REG);

		do {
			regVal = readSpiReg(INDEX_DATA_REG);
		} while (((regVal>>8) & RESET_MASK) == 0);

		do {
			regVal = readSpiReg(BYTE_COUNT_REG);
		} while(regVal == 0);
	}

	void interrupt_reg(uint8_t mask, uint8_t state) {
		uint16_t regVal;

		regVal = readSpiReg(INTR_MASK_REG);
		regVal = ((regVal & ~mask) | state) << 8;
		regVal |= mask;

		writeSpiReg(INTR_REG, regVal);

		return;
	}

	error_t process_isr() {
		uint8_t next_cmd = 0;
		uint8_t intr_val;
		uint16_t rx_byte_cnt;
		error_t ret = FAIL;

		hdr[0] = 0x40 | INTR_REG;
		hdr[1] = 0x00;
		hdr[2] = 0x00;
		spi_transfer(hdr, 3, 1);

		intr_val = hdr[1] & hdr[2];
		hdr[0] = INTR_REG;
		if ((intr_val & INTR_MASK_FIFO1) == INTR_MASK_FIFO1) {
			hdr[1] = INTR_MASK_FIFO1;
			next_cmd = BYTE_COUNT_FIFO1_REG;
		}
		else if ( (intr_val & INTR_MASK_FIFO0) == INTR_MASK_FIFO0) {
			hdr[1] = INTR_MASK_FIFO0;
			next_cmd = BYTE_COUNT_FIFO0_REG;
		}
		else {
			return FAIL;
		}

		spi_transfer(hdr, 2, 1);

		hdr[0] = 0x40 | next_cmd;
		hdr[1] = 0x00;
		hdr[2] = 0x00;
		spi_transfer(hdr, 3, 1);

		rx_byte_cnt = (0x0000 | (hdr[1] << 8) | hdr[2]) & 0x0fff;
		if (rx_byte_cnt < MAC_MAX_PACKET_LEN) {
		    	buf[0] = CMD_RD_FIFO;
			spi_transfer(buf, rx_byte_cnt + 1, 1);
			ret = SUCCESS;
		}

		hdr[0] = CMD_RD_FIFO_DONE;
		spi_transfer(hdr, 1, 1);

		return ret;
	}

	void send(uint8_t* locBuf, uint16_t len) {
		hdr[0] = CMD_WT_FIFO_DATA;
		hdr[1] = MAC_TYPE_TXDATA_REQ;
		hdr[2] = MAC_SUBTYPE_TXDATA_REQ_STD;
		hdr[3] = 0x00;
		hdr[4] = 0x00;
		spi_transfer(hdr, 5, 0);

		locBuf[6] = 0xaa;
		locBuf[7] = 0xaa;
		locBuf[8] = 0x03;
		locBuf[9] = locBuf[10] = locBuf[11] = 0x00;
		spi_transfer(locBuf, len, 1);

		hdr[0] = CMD_WT_FIFO_DONE;
		spi_transfer(hdr, 1, 1);
	}

	static void calc_psk_key(uint8_t* cmd_buf) {
		psk_calc_req_t* cmd = (psk_calc_req_t*)cmd_buf;

		cmd->configBits = 0;
		cmd->phraseLen = strlen((char*)passphrase);
		cmd->ssidLen = strlen((char*)ssid);
		cmd->reserved = 0;
		memset(cmd->ssid, 0x00, 32);
		memcpy(cmd->ssid, ssid, cmd->ssidLen);
		memset(cmd->passPhrase, 0x00, 64);
		memcpy(cmd->passPhrase, passphrase, cmd->phraseLen);

		return;
	}

	static void write_psk_key(uint8_t* cmd_buf) {
		pmk_key_req_t* cmd = (pmk_key_req_t*)cmd_buf;

		cmd->slot = 0;	// WPA/WPA2 PSK slot
		cmd->ssidLen = strlen((char*)ssid);
		memset(cmd->ssid, 0x00, 32);
		memcpy(cmd->ssid, ssid, cmd->ssidLen);
		memcpy(cmd->keyData, wpa_psk_key, MAX_PMK_LEN);

		return;
	}

	command void WlanControl.setSSID(uint8_t *_ssid) {
		strncpy((char*)ssid, (char*)_ssid, sizeof(ssid));
	}

	command void WlanControl.setPassphrase(uint8_t *_passphrase) {
		strncpy((char*)passphrase, (char*)_passphrase, sizeof(passphrase));
	}

	command void WlanControl.setSecurityType(security_type_t type) {
		securityType = type;
	}

	command void WlanControl.setWirelessMode(wireless_mode_t mode) {
		wirelessMode = mode;
	}

	void enable_conn_manage() {
		// enable connection manager
		buf[0] = CMD_WT_FIFO_MGMT;
		buf[1] = MAC_TYPE_MGMT_REQ;
		buf[2] = MAC_SUBTYPE_MGMT_REQ_CONNECT_MANAGE;
		buf[3] = 0x01;	// 0x01 - enable; 0x00 - disable
		buf[4] = 10;		// num retries to reconnect
		buf[5] = 0x10 | 0x02 | 0x01;	// 0x10 -	enable start and stop indication messages
											// 		 	from Mrf24w during reconnection
											// 0x02 -	start reconnection on receiving a deauthentication
											// 			message from the AP
											// 0x01 -	start reconnection when the missed beacon count
											// 			exceeds the threshold. uses default value of
											//			100 missed beacons if not set during initialization
		buf[6] = 0;
		spi_transfer(buf, 7, 1);
		buf[0] = CMD_WT_FIFO_DONE;

		spi_transfer(buf, 1, 1);
	}

	void drv_process() {
		if (process_isr() == SUCCESS) {

			switch (buf[1]) {
			case MAC_TYPE_TXDATA_CONFIRM:
				signal Mac.sendDone(SUCCESS);
				break;
			case MAC_TYPE_MGMT_CONFIRM:
				if (buf[3] == RESULT_SUCCESS) {
					switch (buf[2]) {
					case MAC_SUBTYPE_MGMT_REQ_GET_PARAM:
						mac.bytes.b1 = buf[7];
						mac.bytes.b2 = buf[8];
						mac.bytes.b3 = buf[9];
						mac.bytes.b4 = buf[10];
						mac.bytes.b5 = buf[11];
						mac.bytes.b6 = buf[12];

						switch (securityType) {
						case SECURITY_TYPE_NONE:
							enable_conn_manage();
							break;
						case SECURITY_TYPE_WPA:
						case SECURITY_TYPE_WPA2:
							// Initiate PSK calculation on Mrf24w
							buf[0] = CMD_WT_FIFO_MGMT;
							buf[1] = MAC_TYPE_MGMT_REQ;
							buf[2] = MAC_SUBTYPE_MGMT_REQ_CALC_PSK;
							calc_psk_key(&buf[3]);
							spi_transfer(buf, sizeof(psk_calc_req_t)+3, 1);

							buf[0] = CMD_WT_FIFO_DONE;
							spi_transfer(buf, 1, 1);
							break;
						default:
							break;
						}

						break;
					case MAC_SUBTYPE_MGMT_REQ_CALC_PSK:
						memcpy(wpa_psk_key, ((psk_calc_cnf_t*)&buf[3])->psk, 32);

						// Install the PSK key on Mrf24w
						buf[0] = CMD_WT_FIFO_MGMT;
						buf[1] = MAC_TYPE_MGMT_REQ;
						buf[2] = MAC_SUBTYPE_MGMT_REQ_PMK_KEY;
						write_psk_key(&buf[3]);
						spi_transfer(buf, sizeof(pmk_key_req_t)+3, 1);

						buf[0] = CMD_WT_FIFO_DONE;
						spi_transfer(buf, 1, 1);
						break;
					case MAC_SUBTYPE_MGMT_REQ_PMK_KEY:
						enable_conn_manage();
						break;
					case MAC_SUBTYPE_MGMT_REQ_CONNECT_MANAGE:
						{
						connect_req_t* cmd = (connect_req_t*)&buf[3];

						// start connection to AP
						buf[0] = CMD_WT_FIFO_MGMT;
						buf[1] = MAC_TYPE_MGMT_REQ;
						buf[2] = MAC_SUBTYPE_MGMT_REQ_CONNECT;

						cmd->secType = securityType;

						cmd->ssidLen = strlen((char*)ssid);
						memset(cmd->ssid, 0, 32);
						memcpy(cmd->ssid, ssid, cmd->ssidLen);

						// units of 100 milliseconds
						cmd->sleepDuration = 0;
						cmd->modeBss = wirelessMode;

						spi_transfer(buf, sizeof(connect_req_t)+3, 1);

						buf[0] = CMD_WT_FIFO_DONE;
						spi_transfer(buf, 1, 1);
						}
						break;
					case MAC_SUBTYPE_MGMT_REQ_CONNECT:
						signal SplitControl.startDone(SUCCESS);
						break;
					default:
						break;
					}
				}
				else {
					chipStop();
					signal SplitControl.startDone(FAIL);
				}
				break;

			case MAC_TYPE_RXDATA_INDICATE:
				{
					uint16_t len;
					rx_data_ind_t* ptr = (rx_data_ind_t*)&(buf[3]);

					len = ( ptr->dataLen );

					memcpy(&buf[17], &buf[29], len);				// todo: configure chip to avoid this ???
					signal Mac.received((mac_packet_t*)&(buf[5]));
				}
				break;

			case MAC_TYPE_MGMT_INDICATE:
				switch (buf[2]) {
				case MAC_SUBTYPE_MGMT_IND_DISASSOC:
				case MAC_SUBTYPE_MGMT_IND_DEAUTH:
					chipStop();
					signal SplitControl.startDone(FAIL);		// authentication failed
					break;
				case MAC_SUBTYPE_MGMT_IND_CONN_STATUS:
					{
						uint16_t status = (((uint16_t)(buf[3]))<<8)|buf[4];

						if (status == 1 || status == 5) {
							chipStop();
							signal WlanControl.lostConnection();

						}
						else if (status == 2 || status == 6) {
							// connected
						}
					}
					break;
				}
				break;
			default:
				debug("unknown state");
				break;
			}
		}
	}

	task void isr() {
		resourceState = RESOURCE_DRIVE;
		call Resource.request();
	}

	async event void intWLAN.fired() {
		post isr();
	}

	command error_t Mac.send(mac_packet_t *data, uint16_t len) {
		send((uint8_t*) data, len);

		return SUCCESS;
	}

	command mac_addr_t* Mac.getMac() {
		return &mac;
	}

	command error_t SplitControl.start() {
		call SlaveSelect.makeOutput();
		call SlaveSelect.set();
		resourceState = RESOURCE_START;
		call Resource.request();

		return SUCCESS;
	}

	void start() {
		chip_reset();
		writeSpiReg(INTR2_REG, 0xffff);
		interrupt_reg(0xff, 0);
		interrupt_reg(0x80|0x40, 0x80|0x40);

		call intWLAN.clear();
		call intWLAN.edge(FALSE);	// we want falling edge interrupts
		call intWLAN.enable();

		// get mac addr
		buf[0] = CMD_WT_FIFO_MGMT;
		buf[1] = MAC_TYPE_MGMT_REQ;
		buf[2] = MAC_SUBTYPE_MGMT_REQ_GET_PARAM;
		buf[3] = 0;
		buf[4] = PARAM_MAC_ADDRESS;
		spi_transfer(buf, 5, 1);

		buf[0] = CMD_WT_FIFO_DONE;
		spi_transfer(buf, 1, 1);
	}

	event void Resource.granted() {
		switch (resourceState) {
		case RESOURCE_START:
			start();
			break;
		case RESOURCE_DRIVE:
			drv_process();
			break;
		}
		call Resource.release();
	}

	command error_t SplitControl.stop() {
		return FAIL;
	}

	default event void SplitControl.stopDone(error_t error) {
		// todo: not working ???
	}
}

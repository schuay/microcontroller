/**
 * @author:	Christian Mauser, 0625688 and Alexander Heinisch, 0627820 (TU Wien)
 *
 */

#ifndef MRF24W_H
#define MRF24W_H

#include "wlan.h"


/******************************************************************************
 * Macro definitions for driver state machine
 ******************************************************************************/
 // Command values which appear in PREAMBLE_CMD_IDX for each SPI message
enum {
	CMD_FIFO_ACCESS     = 0x80,
	CMD_WT_FIFO_DATA	= (CMD_FIFO_ACCESS | 0x20),
	CMD_WT_FIFO_MGMT	= (CMD_FIFO_ACCESS | 0x30),
	CMD_RD_FIFO			= (CMD_FIFO_ACCESS | 0x00),
	CMD_WT_FIFO_DONE	= (CMD_FIFO_ACCESS | 0x40),
	CMD_RD_FIFO_DONE	= (CMD_FIFO_ACCESS | 0x50),
	CMD_WT_REG			= 0x00,
	CMD_RD_REG			= 0x40,
};

 // Type values which appear in PREAMBLE_TYPE_IDX for each SPI message
enum {
	MAC_TYPE_TXDATA_REQ			= 1,
	MAC_TYPE_MGMT_REQ			= 2,
};

typedef enum {
	MAC_TYPE_TXDATA_CONFIRM		= 1,
	MAC_TYPE_MGMT_CONFIRM		= 2,
	MAC_TYPE_RXDATA_INDICATE	= 3,
	MAC_TYPE_MGMT_INDICATE		= 4,
} mac_type_t;

 // Subtype values which appear in PREAMBLE_SUBTYPE_IDX for each SPI message
 // Subtype for MAC_TYPE_TXDATA_REQ and MAC_TYPE_TXDATA_CONFIRM
enum {
  MAC_SUBTYPE_TXDATA_REQ_STD			= 1,
};

 // Subtype for MAC_TYPE_MGMT_REQ and MAC_TYPE_MGMT_CONFIRM
enum { 
  MAC_SUBTYPE_MGMT_REQ_PMK_KEY		=	 8,
  MAC_SUBTYPE_MGMT_REQ_WEP_KEY		=	10,
  MAC_SUBTYPE_MGMT_REQ_CALC_PSK		=   12,
  MAC_SUBTYPE_MGMT_REQ_SET_PARAM	=    15,
  MAC_SUBTYPE_MGMT_REQ_GET_PARAM	=	 16,
  MAC_SUBTYPE_MGMT_REQ_ADHOC_START	=	 18,
  MAC_SUBTYPE_MGMT_REQ_CONNECT		=	 19,
  MAC_SUBTYPE_MGMT_REQ_CONNECT_MANAGE	= 20,
};

// Subtype for MAC_TYPE_RXDATA_INDICATE
enum {
	MAC_SUBTYPE_RXDATA_IND_STD			   =  1,
};

// Subtype for MAC_TYPE_MGMT_INDICATE
enum {
	MAC_SUBTYPE_MGMT_IND_DISASSOC		= 1,
	MAC_SUBTYPE_MGMT_IND_DEAUTH			= 2,
	MAC_SUBTYPE_MGMT_IND_CONN_STATUS	= 4,
};

// Parameter IDs for MAC_SUBTYPE_MGMT_REQ_SET_PARAM
enum {
 PARAM_MAC_ADDRESS		=	(1),
};

// MAC result code
enum {
    RESULT_SUCCESS = 1,
    RESULT_INVALID_SUBTYPE,
    RESULT_CANCELLED,
    RESULT_FRAME_EOL,
    RESULT_FRAME_RETRY_LIMIT,
    RESULT_FRAME_NO_BSS,
    RESULT_FRAME_TOO_BIG,
    RESULT_FRAME_ENCRYPT_FAILURE,
    RESULT_INVALID_PARAMS,
    RESULT_ALREADY_AUTH,
    RESULT_ALREADY_ASSOC,
    RESULT_INSUFFICIENT_RSRCS,
    RESULT_TIMEOUT,
    RESULT_BAD_EXCHANGE,	       // frame exchange problem with peer (AP or STA)
    RESULT_AUTH_REFUSED,		    // authenticating node refused our request
    RESULT_ASSOC_REFUSED,   	    // associating node refused our request
    RESULT_REQ_IN_PROGRESS,	    // only one mlme request at a time allowed
    RESULT_NOT_JOINED,			    // operation requires that device be joined
    								          // with target
    RESULT_NOT_ASSOC,			    // operation requires that device be
    								          // associated with target
    RESULT_NOT_AUTH,				    // operation requires that device be
    								          // authenticated with target
    RESULT_SUPPLICANT_FAILED,
    RESULT_UNSUPPORTED_FEATURE,
    RESULT_REQUEST_OUT_OF_SYNC	// Returned when a request is recognized
    								         // but invalid given the current state
    								         // of the MAC
};

/*
 * G2100 command registers
 */
typedef enum {
	INTR_REG				=	0x01,	// 8-bit register containing interrupt bits
	INTR_MASK_REG		=	0x02,	// 8-bit register containing interrupt mask
	SYS_INFO_DATA_REG	=	0x21,	// 8-bit register to read system info data window
	SYS_INFO_IDX_REG	=	0x2b,
	INTR2_REG			=	0x2d,	// 16-bit register containing interrupt bits
	INTR2_MASK_REG		=	0x2e,	// 16-bit register containing interrupt mask
	BYTE_COUNT_REG		=	0x2f,	// 16-bit register containing available write size for fifo0
	BYTE_COUNT_FIFO0_REG	=0x33,	// 16-bit register containing bytes ready to read on fifo0
	BYTE_COUNT_FIFO1_REG	=0x35,	// 16-bit register containing bytes ready to read on fifo1
	PWR_CTRL_REG		=		0x3d,	// 16-bit register used to control low power mode
	INDEX_ADDR_REG		=	0x3e,	// 16-bit register to move the data window
	INDEX_DATA_REG		=	0x3f,	// 16-bit register to read the address in the INDEX_ADDR_REG
} register_t;

enum {
	INTR_REG_LEN			=	1,
	INTR_MASK_REG_LEN		=   1,
	SYS_INFO_DATA_REG_LEN	=   1,
	SYS_INFO_IDX_REG_LEN	=	2,
	INTR2_REG_LEN			=   2,
	INTR2_MASK_REG_LEN		=   2,
	BYTE_COUNT_REG_LEN		=   2,
	BYTE_COUNT_FIFO0_REG_LEN	=2,
	BYTE_COUNT_FIFO1_REG_LEN	=2,
	PWR_CTRL_REG_LEN		=	2,
	INDEX_ADDR_REG_LEN		=   2,
	INDEX_DATA_REG_LEN		=   2,
};

// Registers accessed through INDEX_ADDR_REG
enum {
	RESET_STATUS_REG	=	0x2a,	// 16-bit read only register providing HW status bits
	RESET_REG			 =  0x2e,	// 16-bit register used to initiate hard reset
	PWR_STATUS_REG		=	0x3e,	// 16-bit register read to determine when device
};
											         // out of sleep state
enum {
	RESET_MASK	=		0x10,	// the first byte of the RESET_STATUS_REG
											         // used to determine when the G2100 is in reset

	ENABLE_LOW_PWR_MASK =	0x01,	// used by the Host to enable/disable sleep state
										            // indicates to G2100 that the Host has completed
										            // transactions and the device can go into sleep
											         // state if possible
};

// mask values for INTR_REG and INTR2_REG
enum {
	INTR_MASK_FIFO1		 =  0x80,
	INTR_MASK_FIFO0		 =  0x40,
	INTR_MASK_ALL		 =  0xff,
	INTR2_MASK_ALL		= 0xffff,
};

// Security keys
enum {
	MAX_PMK_LEN					= 32,
};

/******************************************************************************
 * Type definitions
 ******************************************************************************/
typedef struct
{
    uint8_t configBits;
    uint8_t phraseLen;	                           /* number of valid bytes in passphrase */
    uint8_t ssidLen;		                           /* number of valid bytes in ssid */
    uint8_t reserved;	                           /* alignment byte */
    uint8_t ssid[MAX_SSID_LEN];	            /* the string of characters representing the ssid */
    uint8_t passPhrase[MAX_PASSPHRASE_LEN]; /* the string of characters representing the passphrase */
} psk_calc_req_t;

typedef struct
{
    uint8_t result;		         /* indicating success or other */
    uint8_t macState;	         /* current State of the on-chip MAC */
    uint8_t keyReturned;	      /* 1 if psk contains key data, 0 otherwise */
    uint8_t reserved;	         /* pad byte */
    uint8_t psk[MAX_PMK_LEN];	/* the psk bytes */
} psk_calc_cnf_t;

typedef struct
{
    uint8_t slot;
    uint8_t ssidLen;
    uint8_t ssid[MAX_SSID_LEN];
    uint8_t keyData[MAX_PMK_LEN];
} pmk_key_req_t;

typedef struct
{
    uint16_t        rssi;                /* the value of the G1000 RSSI when the data frame was received */
    uint8_t       dstAddr[6]  ;        /* MAC Address to which the data frame was directed. */
    uint8_t       srcAddr[6];          /* MAC Address of the Station that sent the Data frame. */
    uint16_t        arrivalTime_th;      /* the value of the 32-bit G1000 system clock when the frame arrived */
    uint16_t        arrivalTime_bh;
    nx_uint16_t        dataLen;             /* the length in bytes of the payload which immediately follows this data structure */
} rx_data_ind_t;

typedef struct {
	uint8_t secType;		               /* security type : 0 - none; 1 - wep; 2 - wpa; 3 - wpa2; 0xff - best available */
    uint8_t ssidLen;	               	/* num valid bytes in ssid */
    uint8_t ssid[MAX_SSID_LEN];	/* the ssid of the target */
    uint16_t  sleepDuration;          	/* power save sleep duration in units of 100 milliseconds */
    uint8_t modeBss;		            	/* 1 - infra; 2 - adhoc */
    uint8_t reserved;
} connect_req_t;

typedef struct {
	nx_uint8_t addr;
	nx_uint16_t data;
} spi_reg_transfer_t;

#endif

/**
 * @author:	Harald Glanzer, 0727156 TU Wien
 *
 * overhauled by Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 */
#ifndef ENC28J60_H
#define ENC28J60_H

enum {
	MAX_ETHERNET_PACKET_LEN = 250,
	MIN_ETHERNET_PACKET_LEN = 0x3C,

	// buffer boundaries applied to internal 8K ram
	//      entire available packet buffer space is allocated
	TXSTART_INIT	= 0x0000,  // start TX buffer at 0
	RXSTART_INIT	= 0x0600,  // give TX buffer space for one full ethernet frame ~1500 bytes
	RXSTOP_INIT		= 0x1FFF,  // receive buffer gets the rest
};

typedef enum {
	ETH_UNINIT,
	ETH_INITIALIZING,
	ETH_READY,
} ethernet_state_t;

typedef enum {
	LINK_DOWN,
	LINK_UP,
} link_status_t;

enum {
	MAC0	= 0x1,
	MAC1	= 0x2,
	MAC2	= 0x3,
	MAC3	= 0x4,
	MAC4	= 0x5,
	MAC5	= 0x6,
};

// SPI operation codes
enum {
	ENC28J60_READ_CTRL_REG	= 0x00,
	ENC28J60_READ_BUF_MEM	= 0x3A,
	ENC28J60_WRITE_CTRL_REG	= 0x40,
	ENC28J60_WRITE_BUF_MEM	= 0x7A,
	ENC28J60_BIT_FIELD_SET	= 0x80,
	ENC28J60_BIT_FIELD_CLR	= 0xA0,
	ENC28J60_SOFT_RESET		= 0xFF,
};

// register definitions
enum {
	ADDR_MASK	= 0x1F,
	BANK_MASK	= 0x60,
	SPRD_MASK	= 0x80,
	// All-bank registers
	EIE			= 0x1B,
	EIR			= 0x1C,
	ESTAT		= 0x1D,
	ECON2		= 0x1E,
	ECON1		= 0x1F,
	// Bank 0 registers
	ERDPTL		= 0x00,
	ERDPTH		= 0x01,
	EWRPTL		= 0x02,
	EWRPTH		= 0x03,
	ETXSTL		= 0x04,
	ETXSTH		= 0x05,
	ETXNDL		= 0x06,
	ETXNDH		= 0x07,
	ERXSTL		= 0x08,
	ERXSTH		= 0x09,
	ERXNDL		= 0x0A,
	ERXNDH		= 0x0B,
	ERXRDPTL	= 0x0C,
	ERXRDPTH	= 0x0D,
	ERXWRPTL	= 0x0E,
	ERXWRPTH	= 0x0F,
	EDMASTL		= 0x10,
	EDMASTH		= 0x11,
	EDMANDL		= 0x12,
	EDMANDH		= 0x13,
	EDMADSTL	= 0x14,
	EDMADSTH	= 0x15,
	EDMACSL		= 0x16,
	EDMACSH		= 0x17,
	// Bank 1 registers,
	EHT0		= 0x00,
	EHT1		= 0x01,
	EHT2		= 0x02,
	EHT3		= 0x03,
	EHT4		= 0x04,
	EHT5		= 0x05,
	EHT6		= 0x06,
	EHT7		= 0x07,
	EPMM0		= 0x08,
	EPMM1		= 0x09,
	EPMM2		= 0x0A,
	EPMM3		= 0x0B,
	EPMM4		= 0x0C,
	EPMM5		= 0x0D,
	EPMM6		= 0x0E,
	EPMM7		= 0x0F,
	EPMCSL		= 0x10,
	EPMCSH		= 0x11,
	EPMOL		= 0x14,
	EPMOH		= 0x15,
	EWOLIE		= 0x16,
	EWOLIR		= 0x17,
	ERXFCON		= 0x18,
	EPKTCNT		= 0x19,

	// Bank 2 registers
	MACON1		= 0x00,
	MACON2		= 0x01,
	MACON3		= 0x02,
	MACON4		= 0x03,
	MABBIPG		= 0x04,
	MAIPGL		= 0x06,
	MAIPGH		= 0x07,
	MACLCON1	= 0x08,
	MACLCON2	= 0x09,
	MAMXFLL		= 0x0A,
	MAMXFLH		= 0x0B,
	MAPHSUP		= 0x0D,
	MICON		= 0x11,
	MICMD		= 0x12,
	MIREGADR	= 0x14,
	MIWRL		= 0x16,
	MIWRH		= 0x17,
	MIRDL		= 0x18,
	MIRDH		= 0x19,

	// Bank 3 registers
	MAADR1		= 0x00,
	MAADR0		= 0x01,
	MAADR3		= 0x02,
	MAADR2		= 0x03,
	MAADR5		= 0x04,
	MAADR4		= 0x05,
	EBSTSD		= 0x06,
	EBSTCON		= 0x07,
	EBSTCSL		= 0x08,
	EBSTCSH		= 0x09,
	MISTAT		= 0x0A,
	EREVID		= 0x12,
	ECOCON		= 0x15,
	EFLOCON		= 0x17,
	EPAUSL		= 0x18,
	EPAUSH		= 0x19,

	// PHY registers
	PHCON1		= 0x00,
	PHSTAT1		= 0x01,
	PHHID1		= 0x02,
	PHHID2		= 0x03,
	PHCON2		= 0x10,
	PHSTAT2		= 0x11,
	PHIE		= 0x12,
	PHIR		= 0x13,
	PHLCON		= 0x14,
};

// bit definitions
enum {
	// ENC28J60 EIE Register Bit Definitions
	INTIE		= 0x80,
	PKTIE		= 0x40,
	DMAIE		= 0x20,
	LINKIE		= 0x10,
	TXIE		= 0x08,
	WOLIE		= 0x04,
	TXERIE		= 0x02,
	RXERIE		= 0x01,
	// ENC28J60 EIR Register Bit Definitions
	PKTIF		= 0x40,
	DMAIF		= 0x20,
	LINKIF		= 0x10,
	TXIF		= 0x08,
	WOLIF		= 0x04,
	TXERIF		= 0x02,
	RXERIF		= 0x01,
	// ENC28J60 ESTAT Register Bit Definitions
	INT			= 0x80,
	LATECOL		= 0x10,
	RXBUSY		= 0x04,
	TXABRT		= 0x02,
	CLKRDY		= 0x01,
	// ENC28J60 ECON2 Register Bit Definitions
	AUTOINC		= 0x80,
	PKTDEC		= 0x40,
	PWRSV		= 0x20,
	VRPS		= 0x08,
	// ENC28J60 ECON1 Register Bit Definitions
	TXRST		= 0x80,
	RXRST		= 0x40,
	DMAST		= 0x20,
	CSUMEN		= 0x10,
	TXRTS		= 0x08,
	ERXEN		= 0x04,
	BSEL1		= 0x02,
	BSEL0		= 0x01,
	// ENC28J60 MACON1 Register Bit Definitions
	LOOPBK		= 0x10,
	TXPAUS		= 0x08,
	RXPAUS		= 0x04,
	PASSALL		= 0x02,
	MARXEN		= 0x01,
	// ENC28J60 MACON2 Register Bit Definitions
	MARST		= 0x80,
	RNDRST		= 0x40,
	MARXRST		= 0x08,
	RFUNRST		= 0x04,
	MATXRST		= 0x02,
	TFUNRST		= 0x01,
	// ENC28J60 MACON3 Register Bit Definitions
	PADCFG2		= 0x80,
	PADCFG1		= 0x40,
	PADCFG0		= 0x20,
	TXCRCEN		= 0x10,
	PHDRLEN		= 0x08,
	HFRMLEN		= 0x04,
	FRMLNEN		= 0x02,
	FULDPX		= 0x01,
	// ENC28J60 MICMD Register Bit Definitions
	MIISCAN		= 0x02,
	MIIRD		= 0x01,
	// ENC28J60 MISTAT Register Bit Definitions
	NVALID		= 0x04,
	SCAN		= 0x02,
	ENBUSY		= 0x01,
	// ENC28J60 PHY PHCON1 Register Bit Definitions
	PRST		= 0x8000,
	PLOOPBK		= 0x4000,
	PPWRSV		= 0x0800,
	PDPXMD		= 0x0100,
	// ENC28J60 PHY PHSTAT1 Register Bit Definitions
	PFDPX		= 0x1000,
	PHDPX		= 0x0800,
	LLSTAT		= 0x0004,
	JBSTAT		= 0x0002,
	// ENC28J60 PHY PHCON2 Register Bit Definitions
	FRCLINK		= 0x4000,
	TXDIS		= 0x2000,
	JABBER		= 0x0400,
	HDLDIS		= 0x0100,
	// ENC28J60 Packet Control Byte Bit Definitions
	PHUGEEN		= 0x08,
	PPADEN		= 0x04,
	PCRCEN		= 0x02,
	POVERRIDE	= 0x01,

	UCEN		= 0x80,
	ANDOR		= 0x40,
	CRCEN		= 0x20,
	BCEN		= 0x01,
};
#endif

/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	22.01.2012
 */

configuration HplAtm128GeneralIOFastPortC {
	provides interface GeneralIOPort as PortA;
	provides interface GeneralIOPort as PortB;
	provides interface GeneralIOPort as PortC;
	provides interface GeneralIOPort as PortD;
	provides interface GeneralIOPort as PortE;
	provides interface GeneralIOPort as PortF;
	provides interface GeneralIOPort as PortG;

	provides interface GeneralIOPort as PortH;
	provides interface GeneralIOPort as PortJ;
	provides interface GeneralIOPort as PortK;
	provides interface GeneralIOPort as PortL;
}

implementation {
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTA, (uint8_t)&DDRA, (uint8_t)&PINA) as PortAP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTB, (uint8_t)&DDRB, (uint8_t)&PINB) as PortBP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTC, (uint8_t)&DDRC, (uint8_t)&PINC) as PortCP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTD, (uint8_t)&DDRD, (uint8_t)&PIND) as PortDP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTE, (uint8_t)&DDRE, (uint8_t)&PINE) as PortEP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTF, (uint8_t)&DDRF, (uint8_t)&PINF) as PortFP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTG, (uint8_t)&DDRG, (uint8_t)&PING) as PortGP;

	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTH, (uint8_t)&DDRH, (uint8_t)&PINH) as PortHP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTJ, (uint8_t)&DDRJ, (uint8_t)&PINJ) as PortJP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTK, (uint8_t)&DDRK, (uint8_t)&PINK) as PortKP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTL, (uint8_t)&DDRL, (uint8_t)&PINL) as PortLP;



	PortA = PortAP;
	PortB = PortBP;
	PortC = PortCP;
	PortD = PortDP;
	PortE = PortEP;
	PortF = PortFP;
	PortG = PortGP;

	PortH = PortHP;
	PortJ = PortJP;
	PortK = PortKP;
	PortL = PortLP;
}

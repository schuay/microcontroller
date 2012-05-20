/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @author:	Markus Hartmann <e9808811@student.tuwien.ac.at>
 * @date:	22.01.2012
 *
 * For compatibility it is adviced to use HplAtm128GeneralIOFastPortC
 */

configuration HplAtm1280GeneralIOFastPortC {
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

	components new HplAtm1280GeneralIOFastPortP((uint16_t)&PORTH, (uint16_t)&DDRH, (uint16_t)&PINH) as PortHP;
	components new HplAtm1280GeneralIOFastPortP((uint16_t)&PORTJ, (uint16_t)&DDRJ, (uint16_t)&PINJ) as PortJP;
	components new HplAtm1280GeneralIOFastPortP((uint16_t)&PORTK, (uint16_t)&DDRK, (uint16_t)&PINK) as PortKP;
	components new HplAtm1280GeneralIOFastPortP((uint16_t)&PORTL, (uint16_t)&DDRL, (uint16_t)&PINL) as PortLP;



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

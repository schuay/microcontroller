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
}

implementation {
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTA, (uint8_t)&DDRA, (uint8_t)&PINA) as PortAP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTB, (uint8_t)&DDRB, (uint8_t)&PINB) as PortBP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTC, (uint8_t)&DDRC, (uint8_t)&PINC) as PortCP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTD, (uint8_t)&DDRD, (uint8_t)&PIND) as PortDP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTE, (uint8_t)&DDRE, (uint8_t)&PINE) as PortEP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTF, (uint8_t)&DDRF, (uint8_t)&PINF) as PortFP;
	components new HplAtm128GeneralIOFastPortP((uint8_t)&PORTG, (uint8_t)&DDRG, (uint8_t)&PING) as PortGP;

	PortA = PortAP;
	PortB = PortBP;
	PortC = PortCP;
	PortD = PortDP;
	PortE = PortEP;
	PortF = PortFP;
	PortG = PortGP;
}

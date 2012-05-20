/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

configuration ArpC {
	provides interface Arp;
	uses interface IpControl;
}

implementation {
	components ArpP;
	components new TimerMilliC();
	components new TimerMilliC() as ClearCacheTimeoutC;
	components new LlcC(ETHER_TYPE_ARP);
	components LlcTransceiverC;
	components new PacketQueueC(arp_packet_t, 2);
	components MainC;

	ArpP.Arp = Arp;
	ArpP.Timeout -> TimerMilliC;
	ArpP.ClearCacheTimeout -> ClearCacheTimeoutC;
	ArpP.LlcSend -> LlcC.LlcSend;
	ArpP.LlcReceive -> LlcC.LlcReceive;
	ArpP.IpControl = IpControl;
	ArpP.MacControl -> LlcTransceiverC.MacControl;
	ArpP.PacketQueue -> PacketQueueC;
	ArpP.PacketSender <- PacketQueueC;
	MainC.SoftwareInit -> ArpP.Init;
}

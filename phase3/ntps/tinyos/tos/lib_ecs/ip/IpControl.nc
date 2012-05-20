/**
 * @author:	Andreas Hagmann <ahagmann@ecs.tuwien.ac.at>
 * @date:	12.12.2011
 *
 * based on an implementation of Harald Glanzer, 0727156 TU Wien
 */

interface IpControl {
	command void setIp(in_addr_t *ip);
	command void setGateway(in_addr_t *gateway);
	command void setNetmask(in_addr_t *netmask);
	
	command in_addr_t* getIp();
	command in_addr_t* getGateway();
	command in_addr_t* getNetmask();
}

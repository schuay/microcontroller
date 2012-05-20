#include "wlan.h"

interface WlanControl {
	command void setSSID(uint8_t *ssid);
	command void setPassphrase(uint8_t *passphrase);
	command void setSecurityType(security_type_t type);
	command void setWirelessMode(wireless_mode_t mode);
	event void lostConnection();
}

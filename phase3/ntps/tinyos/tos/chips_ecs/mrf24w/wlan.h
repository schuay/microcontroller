#ifndef WLAN_H
#define WLAN_H

enum {
	MAX_SSID_LEN	= 32,
	MAX_PASSPHRASE_LEN = 128,
};

typedef enum {
	SECURITY_TYPE_NONE	= 0,
	SECURITY_TYPE_WPA	= 2,
	SECURITY_TYPE_WPA2	= 3,
} security_type_t;

typedef enum {
	WIRELESS_MODE_INFRA	= 1,
	WIRELESS_MODE_ADHOC	= 2,
} wireless_mode_t;

#endif

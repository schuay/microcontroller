#include <stdbool.h>
#include <stdlib.h>
#include <util/atomic.h>
#include <wii_user.h>

static uint8_t _state[WII], _leds[WII], _rumbler[WII];

static void (*_rcvButton)(uint8_t, uint16_t);
static void (*_rcvAccel)(uint8_t, uint16_t, uint16_t, uint16_t);

static union
{
	void (*setLedsCallback)(uint8_t, error_t);
	void (*setAccelCallback)(uint8_t, error_t);
	void (*setRumblerCallback)(uint8_t, error_t);
} _union[WII];

static void sndCallback(uint8_t wii)
{
	uint8_t state = _state[wii];
	_state[wii] = 0;
	if (state == 1)		// todo: switch? names for states ???
	{
		if (_union[wii].setLedsCallback)
			_union[wii].setLedsCallback(wii, SUCCESS);
	}
	else if (state == 2)
	{
		if (_union[wii].setAccelCallback)
			_union[wii].setAccelCallback(wii, SUCCESS);
	}
	else if (state == 3)
	{
		if (_union[wii].setRumblerCallback)
			_union[wii].setRumblerCallback(wii, SUCCESS);
	}
}

static void rcvCallback(uint8_t wii, uint8_t length, const uint8_t data[])
{
	if (length > 1)
	{
		if (data[1] == 0x31)
		{
			if (length != 7)
				abort();
			if (_rcvAccel)
			{
				uint16_t x = data[4] << 2 | (data[2] & 0x60) >> 5;
				uint16_t y = data[5] << 1 | (data[3] & 0x20) >> 5;
				uint16_t z = data[6] << 1 | (data[3] & 0x40) >> 6;
				_rcvAccel(wii, x, y, z);
			}
		}
		else
		{
			if (data[1] != 0x30)
				return;
			if (length != 4)
				abort();
		}
		if (_rcvButton)
			_rcvButton(wii, (data[2] & 0x1f) << 8 | (data[3] & 0x9f));
	}
}

error_t wiiUserInit(void (*rcvButton)(uint8_t, uint16_t), void (*rcvAccel)(uint8_t, uint16_t, uint16_t, uint16_t))
{
#ifndef NDEBUG
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		static bool _init;
		if (_init)
			return ERROR;
		_init = true;
	}
#endif
	_rcvButton = rcvButton;
	_rcvAccel = rcvAccel;
	return wiiBtInit(&sndCallback, &rcvCallback);
}

error_t wiiUserConnect(uint8_t wii, const uint8_t *mac, void (*conCallback)(uint8_t, connection_status_t))
{
	return wiiBtConnect(wii, mac, conCallback);
}

error_t wiiUserSetLeds(uint8_t wii, uint8_t bitmask, void (*setLedsCallback)(uint8_t wii, error_t status))
{
#ifndef NDEBUG
	if (wii >= WII)
		return ERROR;
#endif
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		if (_state[wii])
			return 1;
		_state[wii] = 1;
	}
	_leds[wii] = bitmask << 4;
	_union[wii].setLedsCallback = setLedsCallback;
	uint8_t data[] = { 0xa2, 0x11, _leds[wii] | _rumbler[wii] };
	uint8_t status = wiiBtSendRaw(wii, sizeof(data), data);
	if (status)
		_state[wii] = 0;
	return status;
}

error_t wiiUserSetAccel(uint8_t wii, uint8_t enable, void (*setAccelCallback)(uint8_t, error_t))
{
#ifndef NDEBUG
	if (wii >= WII)
		return ERROR;
#endif
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		if (_state[wii])
			return ERROR;
		_state[wii] = 2;
	}
	_union[wii].setAccelCallback = setAccelCallback;
	uint8_t data[] = { 0xa2, 0x12, 0x00, 0x31 };
	uint8_t status = wiiBtSendRaw(wii, sizeof(data), data);
	if (status)
		_state[wii] = 0;
	return status;
}

error_t wiiUserSetRumbler(uint8_t wii, uint8_t enable, void (*setRumblerCallback)(uint8_t, error_t))
{
#ifndef NDEBUG
	if (wii >= WII)
		return ERROR;
#endif
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		if (_state[wii])
			return ERROR;
		_state[wii] = 3;
	}
	_union[wii].setRumblerCallback = setRumblerCallback;
	_rumbler[wii] = enable > 0;
	uint8_t data[] = { 0xa2, 0x11, _leds[wii] | _rumbler[wii] };
	uint8_t status = wiiBtSendRaw(wii, sizeof(data), data);
	if (status)
		_state[wii] = 0;
	return status;
}

#include <stdbool.h>
#include <stdlib.h>
#include <util/atomic.h>
#include <stdio.h>
#include <avr/pgmspace.h>
#include <wii_bt.h>

static void (*_sndCallback)(uint8_t);
static void (*_rcvCallback)(uint8_t, uint8_t, const uint8_t []);

static void (*_conCallback[WII])(uint8_t, connection_status_t);

static bool _data[WII];
static uint8_t _transmit[WII], _receive[WII], _state[WII];
static uint16_t _control[WII], _interrupt[WII];

error_t wiiBtInit(void (*sndCallback)(uint8_t), void (*rcvCallback)(uint8_t, uint8_t, const uint8_t []))
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
	_sndCallback = sndCallback;
	_rcvCallback = rcvCallback;
	return hci_init();
}

error_t wiiBtConnect(uint8_t wii, const uint8_t mac[], void (*conCallback)(uint8_t, connection_status_t))
{
#ifndef NDEBUG
	if (wii >= WII || !mac)
		return ERROR;
#endif
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		if (_control[wii])
			return ERROR;
		_control[wii] = 1;
	}
	_conCallback[wii] = conCallback;
	error_t status = hci_create_connection(wii, mac);
	if (status)
		ATOMIC_BLOCK(ATOMIC_FORCEON)
			_control[wii] = 0;
	return status;
}

void hci_connection_complete(uint8_t wii, uint8_t status)
{
	if (!status)
		hci_number_of_completed_packets(wii);
	else
		hci_disconnection_complete(wii);
}

void hci_disconnection_complete(uint8_t wii)
{
	void (*conCallback)(uint8_t, uint8_t) = _conCallback[wii];
	_state[wii] = 0;
	ATOMIC_BLOCK(ATOMIC_FORCEON)
		_control[wii] = 0;
	if (conCallback)
		conCallback(wii, DISCONNECTED);
}

error_t wiiBtSendRaw(uint8_t wii, uint8_t datagramLength, const uint8_t datagram[])
{
#ifndef NDEBUG
	if (wii >= WII || datagramLength > 23 || !datagram)
		return ERROR;
#endif
	if (_state[wii] < 15 || _state[wii] > 17)
		return ERROR;
	uint8_t data[datagramLength + 4];
	data[0] = datagramLength, data[1] = 0;
	data[2] = _interrupt[wii], data[3] = _interrupt[wii] >> 8;
	for (uint8_t index = 0; index < datagramLength; index++)
		data[index + 4] = datagram[index];
	return hci_transmit(wii, datagramLength + 4, data);
}

static void transmit_connection_request(uint8_t wii, uint8_t psm, uint8_t src)
{
	uint8_t data[12] = { 8, [2] = 1, [4] = 2, [6] = 4 };
	data[5] = _transmit[wii], data[8] = psm, data[10] = src;
	hci_transmit(wii, sizeof(data), data);
}

static void transmit_configuration_request(uint8_t wii, uint16_t dst)
{
	uint8_t data[12] = { 8, [2] = 1, [4] = 4, [6] = 4 };
	data[5] = _transmit[wii], data[8] = dst, data[9] = dst >> 8;
	hci_transmit(wii, sizeof(data), data);
}

static void transmit_configuration_response(uint8_t wii, uint16_t dst)
{
	uint8_t data[14] = { 10, [2] = 1, [4] = 5, [6] = 6 };
	data[5] = _receive[wii], data[8] = dst, data[9] = dst >> 8;
	hci_transmit(wii, sizeof(data), data);
}

/*
static void transmit_disconnection_response(uint8_t wii, uint8_t src, uint16_t dst)
{
	uint8_t data[14] = { 8, [2] = 1, [4] = 7, [6] = 4 };
	data[5] = _receive[wii], data[8] = dst, data[9] = dst >> 8, data[1] = src;
	hci_transmit(wii, sizeof(data), data);
}
*/

void hci_number_of_completed_packets(uint8_t wii)
{
	_data[wii] = false;
	if (!_state[wii])
	{
		_state[wii] = 1;
		transmit_connection_request(wii, 17, 64);
		return;
	}
	if (_state[wii] == 2)
	{
		_state[wii] = 3;
		transmit_configuration_request(wii, _control[wii]);
		return;
	}
	if (_state[wii] == 6)
	{
		_state[wii] = 7;
		transmit_configuration_response(wii, _control[wii]);
		return;
	}
	if (_state[wii] == 7)
	{
		_state[wii] = 8;
		transmit_connection_request(wii, 19, 65);
		return;
	}
	if (_state[wii] == 9)
	{
		_state[wii] = 10;
		transmit_configuration_request(wii, _interrupt[wii]);
		return;
	}
	if (_state[wii] == 13)
	{
		_state[wii] = 14;
		transmit_configuration_response(wii, _interrupt[wii]);
		return;
	}
/*
	if (_state[wii] == 18)
	{
		_state[wii] = 19;
		transmit_disconnection_response(wii, 65, _interrupt[wii]);
		return;
	}
	if (_state[wii] == 20)
	{
		_state[wii] = 21;
		transmit_disconnection_response(wii, 64, _control[wii]);
		return;
	}
*/
	_data[wii] = true;
	if (_state[wii] == 15)
	{
		if (_sndCallback)
			_state[wii] = 16;
		else
			_state[wii] = 17;
		if (_conCallback[wii])
			_conCallback[wii](wii, CONNECTED);
	}
	else if (_state[wii] == 16)
		_sndCallback(wii);
}

static void receive_connection_response(uint8_t wii, uint8_t src, uint16_t dst)
{
	do
	{
		if (src == 64)
		{
			if (_state[wii] != 1)
				break;
			_control[wii] = dst;
			_state[wii] = 2;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
			return;
		}
		if (src == 65)
		{
			if (_state[wii] != 8)
				break;
			_interrupt[wii] = dst;
			_state[wii] = 9;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
			return;
		}
	} while (0);
	printf_P(PSTR("abort at %s:%d\n"), __FILE__, __LINE__); abort();
}

static void receive_configuration_request(uint8_t wii, uint8_t src)
{
	if (src == 64)
	{
		if (_state[wii] == 3)
			_state[wii] = 5;
		else if (_state[wii] == 4)
		{
			_state[wii] = 6;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
		}
	}
	else if (src == 65)
	{
		if (_state[wii] == 10)
			_state[wii] = 12;
		else if (_state[wii] == 11)
		{
			_state[wii] = 13;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
		}
	}
	else {
		printf_P(PSTR("abort at %s:%d\n"), __FILE__, __LINE__); abort();
	}
}

static void receive_configuration_response(uint8_t wii, uint8_t src)
{
	if (src == 64)
	{
		if (_state[wii] == 3)
			_state[wii] = 4;
		else if (_state[wii] == 5)
		{
			_state[wii] = 6;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
		}
	}
	else if (src == 65)
	{
		if (_state[wii] == 10)
			_state[wii] = 11;
		else if (_state[wii] == 12)
		{
			_state[wii] = 13;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
		}
	}
	else {
		printf_P(PSTR("abort at %s:%d\n"), __FILE__, __LINE__); abort();
	}
}

/*
static void receive_disconnection_request(uint8_t wii, uint8_t dst, uint16_t src)
{
	do
	{
		if (dst == 65)
		{
			if (src != _interrupt[wii])
				break;
			if (_state[wii] != 16 && _state[wii] != 17)
				break;
			_state[wii] = 18;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
			return;
		}
		if (dst == 64)
		{
			PORTA++;
			if (src != _control[wii])
				break;
			if (_state[wii] != 19)
				break;
			_state[wii] = 20;
			if (_data[wii])
				hci_number_of_completed_packets(wii);
			return;
		}
	} while (0);
	printf_P(PSTR("abort at %s:%d\n"), __FILE__, __LINE__); abort();
}
*/

void hci_receive(uint8_t wii, uint8_t length, const uint8_t data[])
{
	do
	{
		if (length < 5 || length - 4 != data[0] || data[1])
			break;
		if (data[2] == 1 && !data[3])
		{
			data += 4;
			if (length < 8 || data[2] != length - 8 || data[3])
				break;
			length -= 8;
			if (data[0] == 3)
			{
				if (data[1] != _transmit[wii] || length != 8)
					break;
				if (data[7] || data[8] > 1 || data[9])
					break;
				if (!data[8])
				{
					_transmit[wii]++;
					uint16_t dst = data[5] << 8 | data[4];
					receive_connection_response(wii, data[6], dst);
				}
				return;
			}
			if (data[0] == 4)
			{
				if (length < 4 || data[5])
					break;
				_receive[wii] = data[1];
				receive_configuration_request(wii, data[4]);
				return;
			}
			if (data[0] == 5)
			{
				if (data[1] != _transmit[wii] || length < 6)
					break;
				_transmit[wii]++;
				if (data[5] || data[6] & 1 || data[8] || data[9])
					break;
				receive_configuration_response(wii, data[4]);
				return;
			}
			if (data[0] == 6)
			{
/*
				if (length != 4 || data[5])
					break;
				_receive[wii] = data[1];
				uint16_t src = data[7] << 8 | data[6];
				receive_disconnection_request(wii, data[4], src);
*/
				return;
			}
		}
		else if (data[2] == 65 && !data[3])
		{
			if (_state[wii] < 14)
				break;
			if (_state[wii] == 14)
			{
				_state[wii] = 15;
				if (_data[wii])
					hci_number_of_completed_packets(wii);
			}
			if (_rcvCallback)
				_rcvCallback(wii, length - 4, &data[4]);
			return;
		}
	} while (0);
	printf_P(PSTR("abort at %s:%d\n"), __FILE__, __LINE__); abort();
}

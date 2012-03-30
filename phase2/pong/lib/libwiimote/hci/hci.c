#include <stdbool.h>
#include <stdlib.h>
#include <util/atomic.h>

#include "hal_wt41_fc_uart.h"
#include "hci.h"

#ifndef WII
#define WII 4
#endif

typedef volatile struct buffer
{
	uint8_t length, data[32];
	volatile struct buffer *next;
} buffer_t;

static buffer_t *volatile _first = 0, *volatile _last = (buffer_t *)1;

static buffer_t _command = { 17, { [1] = 5, 4, 13, [10] = 24, 204, 1 } };

static volatile uint8_t _create = WII;
static volatile uint16_t _handle[] = { [0 ... WII - 1] = 0xF000 };

static buffer_t _data[] = { [0 ... WII - 1] = { .data = { 2 } } };
static volatile bool _packet[WII];

static void sndCallback(void)
{
	static uint8_t _offset;
	buffer_t *first;
	ATOMIC_BLOCK(ATOMIC_RESTORESTATE)
	{
		first = _first;
		if (__builtin_expect(!first, 0))
		{
			_last = 0;
			return;
		}
	}
	uint8_t offset = _offset, c = first->data[offset++];
	if (__builtin_expect(offset == first->length, 0))
		_first = first->next, first->next = 0, offset = 0;
	_offset = offset;
	halWT41FcUartSend(c);
}

static void transmit(buffer_t *buffer)
{
	buffer_t *last;
	ATOMIC_BLOCK(ATOMIC_RESTORESTATE)
	{
		last = _last, _last = buffer;
		if (_first)
		{
			last->next = buffer;
			return;
		}
		_first = buffer;
	}
	if (!last)
		sndCallback();
}

error_t hci_create_connection(uint8_t wii, const uint8_t address[])
{
#ifndef NDEBUG
	if (__builtin_expect(wii >= WII || !address, 0))
		abort();
#endif
	ATOMIC_BLOCK(ATOMIC_FORCEON)
	{
		if (_handle[wii] < 0x1000 || _create < WII)
			return ERROR;
		_create = wii;
	}
	for (uint8_t index = 0; index < 6; index++)
		_command.data[index + 4] = address[5 - index];
	transmit(&_command);
	return SUCCESS;
}

error_t hci_transmit(uint8_t wii, uint8_t length, const uint8_t data[])
{
#ifndef NDEBUG
	if (__builtin_expect(wii >= WII || length > 27, 0))
		abort();
#endif
	uint16_t handle;
	ATOMIC_BLOCK(ATOMIC_RESTORESTATE)
	{
		handle = _handle[wii];
		if (handle > 0x0FFF || _packet[wii])
			return ERROR;
		_packet[wii] = true;
	}
	_data[wii].length = length + 5;
	_data[wii].data[1] = handle;
	_data[wii].data[2] = 0x20 | handle >> 8;
	_data[wii].data[3] = length;
	for (uint8_t index = 0; index < length; index++)
		_data[wii].data[index + 5] = data[index];
	transmit(&_data[wii]);
	return SUCCESS;
}

static void event(uint8_t code, uint8_t length, const uint8_t parameters[])
{
	do
	{
		if (code == 3)
		{
			if (length != 11 || _create >= WII)
				break;
			for (uint8_t index = 0;; index++)
			{
				if (parameters[index + 3] != _command.data[index + 4])
					break;
				if (index < 5)
					continue;
				uint8_t wii = _create, status = parameters[0];
				if (!status)
				{
					if (parameters[9] != 1 || parameters[10])
						break;
					if (parameters[2] > 0x0F)
						break;
					union { uint8_t byte[2]; uint16_t word; } handle =
						{ { parameters[1], parameters[2] } };
					_handle[wii] = handle.word;
				}
				_create = WII;
				hci_connection_complete(wii, status);
				return;
			}
		}
		else if (code == 5)
		{
			if (length != 4 || parameters[0])
				break;
			union { uint8_t byte[2]; uint16_t word; } handle =
				{ { parameters[1], parameters[2] } };
			for (uint8_t wii = 0; wii < WII; wii++)
			{
				if (handle.word != _handle[wii])
					continue;
				_handle[wii] = 0x1000;
				_packet[wii] = false;
				hci_disconnection_complete(wii);
				return;
			}
		}
		else if (code == 13)
			return;
		if (code == 15)
		{
			if (length != 4 || parameters[1] != 1)
				break;
			if (!_command.data[0])
			{
				if (parameters[2] || parameters[3])
					break;
				_command.data[0] = 1;
				sndCallback();
			}
			else
			{
				if (parameters[2] != 5 || parameters[3] != 4)
					break;
				buffer_t *next, *last;
				ATOMIC_BLOCK(ATOMIC_FORCEON)
					next = _command.next, last = _last;
				if (next || &_command == last)
					break;
				uint8_t status = parameters[0];
				if (status)
				{
					uint8_t wii = _create;
					_create = WII;
					hci_connection_complete(wii, status);
				}
			}
			return;
		}
		else if (code == 19)
		{
			if (!length || parameters[0] > 29)
				break;
			if (length != 1 + 4 * parameters[0])
				break;
			uint8_t count = parameters[0];
			for (uint8_t index = 0; index < count; index++)
			{
				if (parameters[3 + index * 4] != 1 || parameters[4 + index * 4])
					abort();
				union { uint8_t byte[2]; uint16_t word; } handle =
					{ { parameters[1 + index * 4], parameters[2 + index * 4] } };
				for (uint8_t wii = 0; wii < WII; wii++)
				{
					if (handle.word != _handle[wii])
						continue;
					if (!_packet[wii])
						abort();
					buffer_t *next, *last;
					ATOMIC_BLOCK(ATOMIC_FORCEON)
						next = _data[wii].next, last = _last;
					if (next || &_data[wii] == last)
						abort();
					_packet[wii] = false;
					hci_number_of_completed_packets(wii);
				}
			}
			return;
		}
	} while (0);
	abort();
}

static void rcvCallback(uint8_t value)
{
	static uint8_t _state, _length, _offset;
	static union { struct { uint8_t connection, data[27]; } data;
		struct { uint8_t code, parameters[29]; } event; } _union;
	do
	{
		if (_state != 0x42)
		{
			if (_state != 0x24)
			{
				if (!_state)
				{
					if (value != 0x02 && value != 0x04)
						break;
					_state = value;
				}
				else if (_state == 0x02)
				{
					_union.data.connection = value;
					_state = 0x12;
				}
				else if (_state == 0x12)
				{
					if ((value & 0xF0) != 0x20)
						break;
					union { uint8_t byte[2]; uint16_t word; } handle =
						{ { _union.data.connection, value & 0x0F } };
					for (uint8_t index = 0; index < WII; index++)
						if (_handle[index] == handle.word)
						{
							_union.data.connection = index;
							_state = 0x22;
							return;
						}
					break;
				}
				else if (_state == 0x22)
				{
					if (!value || value > sizeof(_union.data.data))
						break;
					_length = value;
					_state = 0x32;
				}
				else if (_state == 0x32)
				{
					if (value)
						break;
					_state = 0x42;
				}
				else if (_state == 0x04)
				{
					_union.event.code = value;
					_state = 0x14;
				}
				else
				{
					if (value > sizeof(_union.event.parameters))
						break;
					_length = value;
					_state = 0x24;
				}
			}
			else
			{
				_union.event.parameters[_offset++] = value;
				if (_offset == _length)
				{
					_state = _offset = 0;
					event(_union.event.code, _length, _union.event.parameters);
				}
			}
		}
		else
		{
			_union.data.data[_offset++] = value;
			if (_offset == _length)
			{
				_state = _offset = 0;
				hci_receive(_union.data.connection, _length, _union.data.data);
			}
		}
		return;
	} while (0);
	abort();
}

error_t hci_init(void)
{
	return halWT41FcUartInit(&sndCallback, &rcvCallback);
}

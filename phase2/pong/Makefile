PROG = avrprog2
GCC = avr-gcc
DOXYGEN = doxygen

MCU = atmega1280

CFLAGS = -mmcu=$(MCU) -Wall -Wextra -Werror -pedantic -Wstrict-prototypes -Os \
		 -DDEBUG -Iinclude -std=gnu99 -frename-registers -fshort-enums \
		 -fpack-struct -c
LDFLAGS = -mmcu=$(MCU) -Wl,-u,vfprintf -lprintf_min 

APP = avr-pong

prot = protocol
lib_mp3 = lib/libmp3
lib_sdcard = lib/libsdcard
lib_wiimote = lib/libwiimote
libs = $(lib_mp3) $(lib_wiimote) $(lib_sdcard) 
libobjects = $(lib_mp3)/mp3.o $(lib_wiimote)/libwiimote.a \
			 $(lib_sdcard)/sdcard.o
source = src/uart.c src/uart_streams.c src/main.c src/lcd.c src/timer.c \
		 src/adc.c src/pong.c src/glcd.c src/glcd_hal.c \
		 src/bt_hal.c src/spi.c
objects = $(source:.c=.o)

.PHONY: all $(libs) doc protocol $(prot)

all: $(APP).elf

doc:
	$(DOXYGEN)

protocol:
	$(MAKE) --directory=$@ $(TARGET)

recursive: $(libs) protocol

$(libs):
	$(MAKE) --directory=$@ $(TARGET)

$(APP).elf: $(libs) $(objects)
	$(GCC) $(LDFLAGS) $(objects) $(libobjects) -o $@

%.o: %.c
	$(GCC) $(CFLAGS) $< -o $@

install: $(APP).elf
	$(PROG) --flash w:$<

clean:
	$(MAKE) recursive TARGET=clean
	$(RM) -f $(objects) $(APP).elf
	$(RM) -rf doc/

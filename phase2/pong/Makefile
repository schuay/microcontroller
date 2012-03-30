PROG = avrprog2
GCC = avr-gcc

MCU = atmega1280

CFLAGS = -mmcu=$(MCU) -Wall -Wextra -pedantic -Wstrict-prototypes -Os \
	 -std=gnu99 -frename-registers -fshort-enums -fpack-struct -c
LDFLAGS = -mmcu=$(MCU) -Wl,-u,vfprintf -lprintf_min 

APP = avr-pong

lib_mp3 = lib/libmp3
lib_sdcard = lib/libsdcard
lib_wiimote = lib/libwiimote
libs = $(lib_mp3) $(lib_wiimote) $(lib_sdcard) 

.PHONY: all $(libs)

all: $(APP).elf

recursive: $(libs)

$(libs):
	$(MAKE) --directory=$@ $(TARGET)

$(APP).elf: $(libs)

%.o: %.c
	$(GCC) $(CFLAGS) $< -o $@

install: $(APP).elf
	$(PROG) --flash w:$<

clean:
	$(MAKE) recursive TARGET=clean

PROG = avrprog2
GCC = avr-gcc

MCU = atmega1280

CFLAGS = -mmcu=$(MCU) -Wall -Wextra -pedantic -Wstrict-prototypes -Os \
	 -std=gnu99 -frename-registers -fshort-enums -fpack-struct -c
LDFLAGS = -mmcu=$(MCU) -Wl,-u,vfprintf -lprintf_min 

APP = avr-pong

lib_glcd = lib/libglcd
lib_mp3 = lib/libmp3
lib_sdcard = lib/libsdcard
lib_wiimote = lib/libwiimote
libs = $(lib_mp3) $(lib_wiimote) $(lib_sdcard) 
libobjects = $(lib_glcd)/libglcd.a $(lib_mp3)/mp3.o \
			 $(lib_wiimote)/libwiimote.a $(lib_sdcard)/sdcard.o
source = src/uart.c src/ringbuffer.c src/uart_streams.c src/main.c
objects = $(source:.c=.o)

.PHONY: all $(libs)

all: $(APP).elf

recursive: $(libs)

$(libs):
	$(MAKE) --directory=$@ $(TARGET)

$(APP).elf: $(libs) $(objects)
	$(GCC) $(LDFLAGS) $(objects) -o $@

%.o: %.c
	$(GCC) $(CFLAGS) $< -o $@

install: $(APP).elf
	$(PROG) --flash w:$<

clean:
	$(MAKE) recursive TARGET=clean
	$(RM) -f $(objects) $(APP).elf

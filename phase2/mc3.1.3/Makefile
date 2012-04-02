TARGET = main
MCU = atmega1280
LFLAGS = -mmcu=$(MCU)
CFLAGS = -mmcu=$(MCU) -c -Os

all: $(TARGET).elf

%.elf: %.o
	avr-gcc $(LFLAGS) $< -o $@

%.o: %.c
	avr-gcc $(CFLAGS) $< -o $@

install: $(TARGET).elf
	avrprog2 --flash w:$<

clean:
	rm -f $(TARGET).o $(TARGET).elf

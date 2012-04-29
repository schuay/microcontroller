TARGET = main
LFLAGS = -mmcu=atmega1280
CFLAGS = -mmcu=atmega1280 -c -Wall -pedantic -Wextra -std=gnu99

all: $(TARGET).elf

%.elf: %.o
	avr-gcc $(LFLAGS) $< -o $@

%.o: %.c
	avr-gcc $(CFLAGS) $< -o $@

install: $(TARGET).elf
	avrprog2 --flash w:$<

clean:
	rm -f $(TARGET).o $(TARGET).elf

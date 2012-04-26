LFLAGS = -mmcu=atmega1280
CFLAGS = -mmcu=atmega1280 -c -Wall -pedantic -Wextra -std=gnu99 -Os
BINS=busy.elf ovf.elf ocmp.elf delay.elf pwm.elf
OBJS=$(BINS:.elf=.o)

all: $(BINS)

%.elf: %.o
	avr-gcc $(LFLAGS) $< -o $@

%.o: %.c
	avr-gcc $(CFLAGS) $< -o $@

install: $(BINS)
	avrprog2 --flash w:$(TARGET)

clean:
	rm -f $(BINS) $(OBJS)

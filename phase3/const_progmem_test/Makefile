LFLAGS = -mmcu=atmega1280
CFLAGS = -mmcu=atmega1280 -c -Wall -pedantic -Wextra -std=gnu99 -Os
TARGET=main.elf
OBJS=$(TARGET:.elf=.o)

all: $(TARGET)

%.elf: %.o
	avr-gcc $(LFLAGS) $< -o $@

%.o: %.c
	avr-gcc $(CFLAGS) $< -o $@

install: $(TARGET)
	avrprog2 --flash w:$(TARGET)

clean:
	rm -f $(TARGET) $(OBJS)

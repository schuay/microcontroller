AS=avr-as
LD=avr-ld
PR=avrprog2

ASFLAGS=-mmcu=atmega1280
LDFLAGS=-mavr51

TARGET=digitalio

all: $(TARGET).elf

$(TARGET).elf: $(TARGET).o lcd.o
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGET).o: $(TARGET).s
	$(AS) $(ASFLAGS) -o $@ $<

install: $(TARGET).elf
	$(PR) --flash w:$<

clean:
	rm -f $(TARGET).elf $(TARGET).o

AS=avr-as
LD=avr-ld
PR=avrprog2

ASFLAGS=-mmcu=atmega1280
LDFLAGS=-mavr51

TARGET=digitalio

all: $(TARGET).elf

%.elf: %.o
	$(LD) $(LDFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

install: $(TARGET).elf
	$(PR) --flash w:$<

clean:
	rm -f $(TARGET).elf $(TARGET).o

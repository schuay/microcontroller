.PHONY: all protocol

all:
	$(MAKE) --directory=src bigAVR6_1280

install:
	$(MAKE) --directory=src bigAVR6_1280 install

check:
	gcc -Wall -Wextra -std=gnu99 src/main.c -o test
	./test; rm -f test

protocol:
	$(MAKE) --directory=$@ $(TARGET)

round: protocol/round.s
	(\
		cd protocol && \
		avr-as -mmcu=atmega1280 round.s -o round.o && \
		avr-ld -mavr51 round.o -o round.elf && \
		avrprog2 --flash w:round.elf \
	)

clean:
	$(MAKE) --directory=src clean
	$(MAKE) --directory=protocol clean
	$(RM) -f protocol/round.elf protocol/round.o

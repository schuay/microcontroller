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

clean:
	$(MAKE) --directory=src clean
	$(MAKE) --directory=protocol clean

all:
	make --directory=src bigAVR6_1280

install:
	make --directory=src bigAVR6_1280 install

check:
	gcc -Wall -Wextra -std=gnu99 src/main.c -o test
	./test; rm -f test

clean:
	make --directory=src clean

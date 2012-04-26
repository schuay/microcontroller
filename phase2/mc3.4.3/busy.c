#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/cpufunc.h>

void setup(void) {
    DDRH = 0xff;
    PORTH = 0x00;
}

int main(void) {
    setup();

    for (;;) {
        /* 50000 ns / 62.5 ns = 800 cycles */

        /*
         *  158:    89 81           ldd r24, Y+1    ; 0x01              2 cycles
         *  15a:   8f 5f           subi    r24, 0xFF   ; 255            1
         *  15c:  89 83           std Y+1, r24    ; 0x01                1
         *  15e: 89 81           ldd r24, Y+1    ; 0x01                 2
         *  160:    88 3c           cpi r24, 0xC8   ; 200               1
         *  162:   d0 f3           brcs    .-12        ; 0x158 <main+0x12>  2
         *
         *  ~9 cycles
         *
         *  800 / 9 = 89
         */

        /* Above calculations are without optimizations.
         * The values below were achieved with trial and error and -Os
         * optimization. */
        for (uint16_t i = 0; i < 160; i++) _NOP();

        PORTH = 0x00;

        for (uint16_t i = 0; i < 80; i++) _NOP();

        PORTH = 1 << 3;
    }
}


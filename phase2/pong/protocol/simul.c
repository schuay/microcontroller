#include <stdio.h>

#define CB_DURATION (42)
#define PACKET_LEN (10)
#define BUF_LEN (49)
#define TRANSMISSION_LEN (64)

int simulate(int cb_duration);

int main(void) {
    int i;

    for (i = 39; simulate(i) != 1; i++) ;

    return 0;
}

int simulate(int cb_duration) {
    int us;     /* Microseconds. We use this both to count time
                   and to simulate the transfer of one bit, since
                   the data rate is 1000000 baud. */
    int byte = 0; /* The number of bytes received. */
    int inbuf = 0; /* The size of the buffer. */

    /* One iteration of the main loop simulates the passing of
     * one us. */
    for (us = 0; us < 1000000; us++) {
        /* A complete packet has been received. */
        if (us % PACKET_LEN == 0) {
            byte++;
            inbuf++;
        }

        /* A new callback run is started, the byte is immediately removed from
         * the buffer. */
        if (us % cb_duration == 0) {
            inbuf--;
        }

        /* If BUF_LEN bytes are contained in the buffer, flow control is
         * triggered. */
        if (inbuf == BUF_LEN) {
            printf("flow control triggered with cb_duration %d at byte: %d,"
                   " inbuf: %d, us: %d\n", cb_duration, byte, inbuf, us);
            return 1;
        }

        if (byte == TRANSMISSION_LEN) {
            printf("transmission completed successfully with cb_duration %d\n",
                    cb_duration);
            break;
        }
    }

    return 0;
}

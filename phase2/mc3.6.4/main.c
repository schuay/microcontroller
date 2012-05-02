#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#include <stdlib.h>

#include "lcd.h"
#include "uart_streams.h"

static bool master;
static int iteration = 0;

/* 5 ms / (62.5 ns * 8) */
#define TIMER_TICKS (10000)

#define SLA_ADDR (0x00) // general call
#define SLA_ACCEPT_GEN_CALL (0x01)
#define RECV_MODE (0x01)
#define SEND_MODE (0x00)

#define STAT_MT_START (0x08)
#define STAT_MT_SLAW_ACK (0x18)
#define STAT_MT_DAT_ACK (0x28)
#define STAT_MT_DAT_NACK (0x30)

#define STAT_MR_START (0x08)
#define STAT_MR_SLAR_ACK (0x40)

#define STAT_SR_SLAW_ACK (0x70) // general call
#define STAT_SR_DAT_ACK (0x90)  // general call
#define STAT_SR_STOP (0xA0)

#define WAIT_FOR_TWINT(msg) do { DEBUG(msg); while (!(TWCR & _BV(TWINT))) ; } while (0);
#define CHECK_STATUS(st) do { uint8_t st_ = TWSR & 0xf8; if (st_ != st) { printf("Line %d, iteration %d: expected 0x%x, got 0x%x\n", __LINE__, iteration, st, st_); abort(); } } while (0);
#define DEBUG(msg) do { printf("DEBUG: line %d, %s\n", __LINE__, msg); } while (0);

#define S_BEGIN_TRANSMISSION() do { TWCR = _BV(TWINT) | _BV(TWEN) | _BV(TWEA); } while (0);

/* It's important not to |= TWCR, but to set it explicitly. */
#define M_BEGIN_TRANSMISSION() do { TWCR = _BV(TWINT) | _BV(TWEN); } while (0);

void setup(void) {
    DDRA = 0x00;
    PORTA = 0xff;

    DDRB = 0xff;

    if (PINA & _BV(PA0)) {
        master = true;
        PORTC |= _BV(7);
    }

    /* prescaler x8, CTC, 5ms */
    TCCR1B |= _BV(CS11) | _BV(WGM12);
    OCR1A = TIMER_TICKS;
    TIMSK1 |= _BV(OCIE1A);

//    initLcd();
    uart_streams_init();

    sleep_enable();
}

void slave_recv(void) {
    TWAR = SLA_ADDR | SLA_ACCEPT_GEN_CALL;

    S_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("SLA_W ACK");
    CHECK_STATUS(STAT_SR_SLAW_ACK);

    S_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("Read data");
    CHECK_STATUS(STAT_SR_DAT_ACK);

    /* read data */
    uint8_t rcvd = TWDR;
    printf("Slave received 0x%x\n", rcvd);
    PORTB = rcvd;

    /* read stop */
    S_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("Stop");
    CHECK_STATUS(STAT_SR_STOP);
}

void master_recv(void) {
    /* send start */
    TWCR = _BV(TWINT) | _BV(TWSTA) | _BV(TWEN); 

    WAIT_FOR_TWINT("Start");
    CHECK_STATUS(STAT_MR_START);

    TWDR = SLA_ADDR | RECV_MODE;

    M_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("SLA_R");
    CHECK_STATUS(STAT_MR_SLAR_ACK);

    /* read data */
    WAIT_FOR_TWINT("Read data");
    PORTB = TWDR;

    /* send stop */
    TWCR = _BV(TWINT) | _BV(TWSTO) | _BV(TWEN); 
    WAIT_FOR_TWINT("Stop");
}

void master_send(void) {
    /* send start */
    TWCR = _BV(TWINT) | _BV(TWSTA) | _BV(TWEN); 

    WAIT_FOR_TWINT("Start");
    CHECK_STATUS(STAT_MT_START);

    TWDR = SLA_ADDR | SEND_MODE;

    M_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("SLA_W");
    CHECK_STATUS(STAT_MT_SLAW_ACK);

    /* send data */
    TWDR = 0xf0;

    M_BEGIN_TRANSMISSION();
    WAIT_FOR_TWINT("Send data");
    CHECK_STATUS(STAT_MT_DAT_ACK);

    /* send stop */
    TWCR = _BV(TWINT) | _BV(TWSTO) | _BV(TWEN); 
}

int main(void) {
    setup();
    sei();

    printf("Hello\n");

    for (;;) {
        if (master) {
            master_send();
        } else {
            slave_recv();
        }
        iteration++;
        sleep_cpu();
    }
}

ISR(TIMER1_COMPA_vect, ISR_BLOCK) {
//    syncScreen(); 
}

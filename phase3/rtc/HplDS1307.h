#ifndef HPLDS1307_H
#define HPLDS1307_H

typedef struct {
    uint8_t seconds :7;
    uint8_t clockHalt :1;   /**< 0: Oscillator enabled, 1: disabled. */
    uint8_t minutes :7;
    uint8_t :1;
    uint8_t hours :6;
    uint8_t hour_mode :1;   /**< 0: 24h, 1: 12h. */
    uint8_t :1;
    uint8_t day :3;
    uint8_t :5;
    uint8_t date :6;
    uint8_t :2;
    uint8_t month :5;
    uint8_t :3;
    uint8_t year :8;
    uint8_t rs :2;          /**< Rate Select: set to 11 by default. */
    uint8_t :2;
    uint8_t sqwe :1;        /**< Square-Wave Enable: set to 0 by default. */
    uint8_t :2;
    uint8_t out :1;         /**< Output Control: set to 0 by default. */
} ds1307_time_mem_t;

#endif

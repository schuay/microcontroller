#ifndef RTC_H
#define RTC_H

typedef struct {
    uint8_t seconds; /**< 0-59 */
    uint8_t minutes; /**< 0-59 */
    uint8_t hours;   /**< 0-23 */
    uint8_t day;     /**< 1-7 */
    uint8_t date;    /**< 1-31 */
    uint8_t month;   /**< 1-12 */
    uint8_t year;    /**< 0-99 */
} rtc_time_t;

#endif

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

#include "minunit.h"

/* Configues source files for testing. */
#define TEST
#define debug(...)

#define FALSE false
#define TRUE true

#include "Rtc.h"
#include "TimeC.nc"
#include "HplDS1307.h"
#include "DS1307C.nc"
#include "GpsTimerParser.h"
#include "GpsTimerParserC.nc"

int tests_run = 0;

static char *test_dayOfWeek_20000101(void)
{
    mu_assert("dayOfWeek(1, 1, 0) == 6", dayOfWeek(1, 1, 0) == 6);
    return 0;
}

static char *test_dayOfWeek_20000322(void)
{
    mu_assert("dayOfWeek(22, 3, 0) == 3", dayOfWeek(22, 3, 0) == 3);
    return 0;
}

static char *test_dayOfWeek_20120322(void)
{
    mu_assert("dayOfWeek(22, 3, 12) == 4", dayOfWeek(22, 3, 12) == 4);
    return 0;
}

static char *test_dayOfWeek_20501225(void)
{
    mu_assert("dayOfWeek(25, 12, 50) == 7", dayOfWeek(25, 12, 50) == 7);
    return 0;
}

static char *test_toNtpTimestamp_20000101_000000(void)
{
    uint32_t dst;
    rtc_time_t src = { 0, 0, 0, 6, 1, 1, 0 };
    toNtpTimestamp(&dst, &src);
    mu_assert("test_toNtpTimestamp_20000101_000000",
            dst == 3155673600UL);
    return 0;
}

static char *test_toNtpTimestamp_20360207_000000(void)
{
    uint32_t dst;
    rtc_time_t src = { 0, 0, 0, 4, 7, 2, 36 };
    toNtpTimestamp(&dst, &src);
    mu_assert("test_toNtpTimestamp_20360207_000000",
            dst == 4294944000UL);
    return 0;
}

static char *test_toNtpTimestamp_20120601_122211(void)
{
    uint32_t dst;
    rtc_time_t src = { 11, 22, 12, 5, 1, 6, 12 };
    toNtpTimestamp(&dst, &src);
    mu_assert("test_toNtpTimestamp_20120601_122211",
            dst == 3547542131UL);
    return 0;
}

static char *test_fromNtpTimestamp_20000101_000000(void)
{
    uint32_t src = 3155673600UL;
    rtc_time_t dst;
    rtc_time_t expected = { 0, 0, 0, 6, 1, 1, 0 };
    fromNtpTimestamp(&dst, &src);
    mu_assert("test_fromNtpTimestamp_20000101_000000",
            memcmp(&dst, &expected, sizeof(dst)) == 0);
    return 0;
}

static char *test_fromNtpTimestamp_20360207_000000(void)
{
    uint32_t src = 4294944000UL;
    rtc_time_t dst;
    rtc_time_t expected = { 0, 0, 0, 4, 7, 2, 36 };
    fromNtpTimestamp(&dst, &src);
    mu_assert("test_fromNtpTimestamp_20360207_000000",
            memcmp(&dst, &expected, sizeof(dst)) == 0);
    return 0;
}

static char *test_fromNtpTimestamp_20120601_122211(void)
{
    uint32_t src = 3547542131UL;
    rtc_time_t dst;
    rtc_time_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    fromNtpTimestamp(&dst, &src);
    mu_assert("test_fromNtpTimestamp_20120601_122211",
            memcmp(&dst, &expected, sizeof(dst)) == 0);
    return 0;
}

static char *test_fromBCD(void)
{
    mu_assert("test_fromBCD", fromBCD(0x99, 0xff) == 99);
    return 0;
}

static char *test_fromBCDMasked(void)
{
    mu_assert("test_fromBCD", fromBCD(0x99, 0x01) == 19);
    return 0;
}

static char *test_toBCD(void)
{
    mu_assert("test_fromBCD", toBCD(99) == 0x99);
    return 0;
}

static char *test_toRtcT(void)
{
    ds1307_time_mem_t src = { .seconds = 0x11, .clockHalt = 0x1, .minutes = 0x22,
                              .hours = 0x12, .hour_mode = 0x0, .day = 0x5, .date = 0x1,
                              .month = 0x6, .year = 0x12, .rs = 0x3, .sqwe = 0x1, .out = 0x1 };
    rtc_time_t dst;
    rtc_time_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    toRtcT(&src, &dst);
    mu_assert("test_toRtcT",
            memcmp(&dst, &expected, sizeof(dst)) == 0);
    return 0;
}

static char *test_toDS1307T(void)
{
    rtc_time_t src = { 11, 22, 12, 5, 1, 6, 12 };
    ds1307_time_mem_t dst = { .clockHalt = 0x1, .hour_mode = 0x0, .rs = 0x3, .sqwe = 0x1, .out = 0x1 };
    ds1307_time_mem_t expected = { .seconds = 0x11, .clockHalt = 0x1, .minutes = 0x22,
                                   .hours = 0x12, .hour_mode = 0x0, .day = 0x5, .date = 0x1,
                                   .month = 0x6, .year = 0x12, .rs = 0x3, .sqwe = 0x1, .out = 0x1 };
    toDS1307T(&src, &dst);
    mu_assert("test_toDS1307T",
            memcmp(&dst, &expected, sizeof(dst)) == 0);
    return 0;
}

static void gpsTimerParserDriver(const char *str)
{
    memset(&testTimedate, 0, sizeof(testTimedate));

    for (unsigned i = 0; i < strlen(str); i++) {
        receivedByte(str[i]);
    }
}

static char *test_gpsTimerParserRegular(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserRegular",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart1(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GP$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart1",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart2(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart2",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart3(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,132113,A$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart3",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart4(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,132113,A,$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart4",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart5(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,123311,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r"
                         "$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart5",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserFalseStart6(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,\n$$$\naffhqfacas09q2e,aga.faskasd\"aflasaf.\r"
                         "$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserFalseStart6",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserInvalidChar(void)
{
    timedate_t expected;
    memset(&expected, 0, sizeof(expected));
    gpsTimerParserDriver("$GPRMC,12A311,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserInvalidChar",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserTrailingGarbage(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n"
                         "$GPRMC,122216,A,3755.3088,N,02401.8008,E,2690.6,84.2,01061A\r\n");
    mu_assert("test_gpsTimerParserTrailingGarbage",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserConsecutiveParse(void)
{
    timedate_t expected = { 20, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n"
                         "$GPRMC,122216,A,3755.3088,N,02401.80615\r\n"
                         "$GPRMC,122220,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n");
    mu_assert("test_gpsTimerParserConsecutiveParse",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *test_gpsTimerParserOtherCommands(void)
{
    timedate_t expected = { 11, 22, 12, 5, 1, 6, 12 };
    gpsTimerParserDriver("$GPGGA,190658,3734.3356,N,02403.6069,E,1,04,5.6,9.7,M,34.5,M,,*46\r\n"
                         "$GPRMC,122211,A,3755.3088,N,02401.8008,E,2690.6,84.2,010612,5,E,A*E\r\n"
                         "$GPGSV,8,1,32,01,50,131,21,02,76,014,43,03,68,080,37,04,69,150,38*71\r\n"
                         "$GPGSV,8,2,32,05,06,053,-24,06,38,032,08,07,40,353,10,08,54,084,25*5D\r\n"
                         "$GPGSV,8,3,32,09,09,074,-21,10,32,199,02,11,03,026,00,12,70,265,38*54\r\n"
                         "$GPGSV,8,4,32,13,79,233,45,14,12,228,-18,15,00,115,00,16,90,181,52*51\r\n"
                         "$GPGSV,8,5,32,17,89,253,51,18,81,274,46,19,02,147,00,20,89,112,51*7C\r\n"
                         "$GPGSV,8,6,32,21,86,236,50,22,61,054,31,23,31,251,01,24,50,183,21*73\r\n"
                         "$GPGSV,8,7,32,25,75,081,43,26,53,044,23,27,85,082,49,28,74,205,42*78\r\n"
                         "$GPGSV,8,8,32,29,19,056,-11,30,68,330,37,31,77,142,44,32,88,059,51*50\r\n");
    mu_assert("test_gpsTimerParserOtherCommands",
            memcmp(&testTimedate, &expected, sizeof(expected)) == 0);
    return 0;
}

static char *all_tests(void)
{
    mu_run_test(test_dayOfWeek_20000101);
    mu_run_test(test_dayOfWeek_20000322);
    mu_run_test(test_dayOfWeek_20120322);
    mu_run_test(test_dayOfWeek_20501225);
    mu_run_test(test_toNtpTimestamp_20000101_000000);
    mu_run_test(test_toNtpTimestamp_20360207_000000);
    mu_run_test(test_toNtpTimestamp_20120601_122211);
    mu_run_test(test_fromNtpTimestamp_20000101_000000);
    mu_run_test(test_fromNtpTimestamp_20360207_000000);
    mu_run_test(test_fromNtpTimestamp_20120601_122211);
    mu_run_test(test_fromBCD);
    mu_run_test(test_fromBCDMasked);
    mu_run_test(test_toBCD);
    mu_run_test(test_toRtcT);
    mu_run_test(test_toDS1307T);
    mu_run_test(test_gpsTimerParserRegular);
    mu_run_test(test_gpsTimerParserFalseStart1);
    mu_run_test(test_gpsTimerParserFalseStart2);
    mu_run_test(test_gpsTimerParserFalseStart3);
    mu_run_test(test_gpsTimerParserFalseStart4);
    mu_run_test(test_gpsTimerParserFalseStart5);
    mu_run_test(test_gpsTimerParserFalseStart6);
    mu_run_test(test_gpsTimerParserInvalidChar);
    mu_run_test(test_gpsTimerParserTrailingGarbage);
    mu_run_test(test_gpsTimerParserConsecutiveParse);
    mu_run_test(test_gpsTimerParserOtherCommands);
    return 0;
}

int main(int argc __attribute__ ((unused)), char **argv __attribute__ ((unused)))
{
    char *result = all_tests();
    if (result != 0) {
        printf("%s\n", result);
    } else {
        printf("ALL TESTS PASSED\n");
    }
    printf("Tests run: %d\n", tests_run);

    return result != 0;
}

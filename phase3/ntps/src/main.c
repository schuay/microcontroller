#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

#include "minunit.h"

/* Configues source files for testing. */
#define TEST

#define FALSE false
#define TRUE true

#include "Rtc.h"
#include "TimeC.nc"
#include "HplDS1307.h"
#include "DS1307C.nc"

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

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include "minunit.h"

/* Configues source files for testing. */
#define TEST

#define FALSE false
#define TRUE true

#include "Rtc.h"
#include "TimeC.nc"

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

static char *all_tests(void)
{
    mu_run_test(test_dayOfWeek_20000101);
    mu_run_test(test_dayOfWeek_20000322);
    mu_run_test(test_dayOfWeek_20120322);
    mu_run_test(test_dayOfWeek_20501225);
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

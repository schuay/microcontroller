#include <avr/pgmspace.h>

#define GCC_VERSION (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)
#define MAGIC (__extension__ 0b01010101)

const uint8_t const_pmem PROGMEM = MAGIC;
typedef const uint8_t const_td_t PROGMEM;
const_td_t const_typedef = MAGIC;
#if GCC_VERSION < 40700
uint8_t pmem PROGMEM = MAGIC;
typedef uint8_t td_t PROGMEM;
td_t nonconst_typedef = MAGIC;
#endif

/**
 * Checks if variables marked PROGMEM are actually stored in program memory.
 * It seems *not* to be the case with const PROGMEM typedefs in avr-gcc 4.5.0.
 *
 * Related: https://bugzilla.redhat.com/show_bug.cgi?id=737950
 */
int main(void)
{
    DDRA = 0xff;
    DDRB = 0xff;
    DDRC = 0xff;
    DDRD = 0xff;
    DDRE = 0xff;

    PORTA = pgm_read_byte(&const_pmem);
    PORTD = pgm_read_byte(&const_typedef); /**< Only this line produces an incorrect value with gcc < 4.7. */
#if GCC_VERSION < 40700
    PORTB = pgm_read_byte(&pmem);
    PORTE = pgm_read_byte(&nonconst_typedef);
#endif
    PORTC = MAGIC;

    for (;;) ;

    return 0;
}

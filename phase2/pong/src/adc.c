#include <avr/io.h>
#include <avr/interrupt.h>

#include "uart_streams.h"
#include <assert.h>

#include "adc.h"

static adc_conv_cmpl_handler_t adc_handler;

void adc_init(const struct adc_conf *conf) {
    assert(conf != NULL);
    assert(conf->conv_cmpl_handler != NULL);

    adc_handler = conf->conv_cmpl_handler;

    /* Apparently, there is no way to set up a reference voltage
     * so that it works no matter how the AREF pin is set up.
     * If REFS1:REFS0 is 0:0, AREF needs to be set to VCC.
     * 1:0 and 1:1 may not be used if an external reference
     * voltage is being applied to the AREF pin (see p289). */

    ADCSRA |= _BV(ADIE);
}

void adc_start_conversion(void) {
    ADCSRA |= _BV(ADEN) | _BV(ADSC);
}

ISR(ADC_vect, ISR_BLOCK) {
    ADCSRA &= ~_BV(ADEN);
    adc_handler(ADC);
}

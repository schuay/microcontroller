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

    ADCSRA |= _BV(ADIE);
}

void adc_start_conversion(void) {
    ADCSRA |= _BV(ADEN) | _BV(ADSC);
}

ISR(ADC_vect, ISR_BLOCK) {
    ADCSRA &= ~_BV(ADEN);
    adc_handler(ADC);
}

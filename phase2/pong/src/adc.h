#ifndef ADC_H
#define ADC_H

/**
 * @file adc.h
 *
 * Handles analog to digital conversions.
 * Note: It seems like voltage reference needs to be
 * set to VCC for this to work.
 */

typedef void (*adc_conv_cmpl_handler_t)(uint16_t);

struct adc_conf {
    adc_conv_cmpl_handler_t conv_cmpl_handler;
};

/**
 * Initializes the ADC.
 */
void adc_init(const struct adc_conf *conf);

/**
 * Starts a conversion and returns immediately.
 * When the result is available, the callback is
 * executed.
 */
void adc_start_conversion(void);

#endif /* ADC_H */

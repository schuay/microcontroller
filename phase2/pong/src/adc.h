#ifndef ADC_H
#define ADC_H

/**
 * @file adc.h
 *
 * Handles analog to digital conversions.
 * Note: Voltage reference AREF *must* be
 * set to VCC for ADC to work.
 */

/**
 * The callback tpe used for reporting ADC results.
 */
typedef void (*adc_conv_cmpl_handler_t)(uint16_t);

/**
 * The ADC configuration struct.
 * conf_cmpl_handler is called when results are available.
 */
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

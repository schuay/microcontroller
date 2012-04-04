typedef void (*adc_conv_cmpl_handler_t)(uint16_t);

struct adc_conf {
    adc_conv_cmpl_handler_t conv_cmpl_handler;
};

void adc_init(const struct adc_conf *conf);
void adc_start_conversion(void);

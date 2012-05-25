interface HplDS1307
{
    command error_t open(void);
    command error_t close(void);
    command error_t registerRead(uint8_t address);
    command error_t registerWrite(uint8_t address, uint8_t data);
    command error_t bulkRead(ds1307_time_mem_t *data);
    command error_t bulkWrite(ds1307_time_mem_t *data);
    async event void registerReadReady(uint8_t value);
    async event void registerWriteReady(void);
    async event void bulkReadReady(void);
    async event void bulkWriteRead(void);
}

module HplDS1307C
{
    provides interface HplDS1307;

    uses interface Resource;
    uses interface I2CPacket<TI2CBasicAddr>;
}

implementation
{
    command error_t HplDS1307.open(void)
    {
    }

    command error_t HplDS1307.close(void)
    {
    }

    command error_t HplDS1307.registerRead(uint8_t address)
    {
    }

    command error_t HplDS1307.registerWrite(uint8_t address, uint8_t data)
    {
    }

    command error_t HplDS1307.bulkRead(ds1307_time_mem_t *data)
    {
    }

    command error_t HplDS1307.bulkWrite(ds1307_time_mem_t *data)
    {
    }

    async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
    }

    async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
    }

    event void Resource.granted()
    {
    }
}

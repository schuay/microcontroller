module HplDS1307C
{
    provides interface HplDS1307;

    uses interface Resource;
    uses interface I2CPacket<TI2CBasicAddr>;
}

#define I2C_ADDR (0b1101000)

#define REG_COUNT (8)

#define REG_SECONDS (0x00)
#define REG_MINUTES (0x01)
#define REG_HOURS (0x02)
#define REG_DAY (0x03)
#define REG_DATE (0x04)
#define REG_MONTH (0x05)
#define REG_YEAR (0x06)
#define REG_CONTROL (0x07)

implementation
{
    static bool inProgress = FALSE;
    static uint8_t buffer[REG_COUNT];

    command error_t HplDS1307.open(void)
    {
        return call Resource.immediateRequest();
    }

    command error_t HplDS1307.close(void)
    {
        if (inProgress) {
            return FAIL;
        }
        return call Resource.release();
    }

    command error_t HplDS1307.registerRead(uint8_t address)
    {
        bool owner = call Resource.isOwner();
        if (!owner) {
            return FAIL;
        }
        /* TODO: since this is async, do we need to copy the data someplace before
         * calling write()?
         * TODO: implementation.
         */
        return call I2CPacket.read(I2C_START | I2C_STOP, I2C_ADDR, 1, buffer);
    }

    command error_t HplDS1307.registerWrite(uint8_t address, uint8_t data)
    {
        bool owner = call Resource.isOwner();
        if (!owner) {
            return FAIL;
        }
    }

    command error_t HplDS1307.bulkRead(ds1307_time_mem_t *data)
    {
        bool owner = call Resource.isOwner();
        if (!owner) {
            return FAIL;
        }
    }

    command error_t HplDS1307.bulkWrite(ds1307_time_mem_t *data)
    {
        bool owner = call Resource.isOwner();
        if (!owner) {
            return FAIL;
        }
    }

    async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
        switch (length) {
        case 1: signal HplDS1307.registerReadReady(*data);
        default: signal HplDS1307.bulkReadReady();
        }
    }

    async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
        switch (length) {
        case 1: signal HplDS1307.registerWriteReady();
        default: signal HplDS1307.bulkWriteReady();
        }
    }

    event void Resource.granted()
    {
        /* Ignored. We use immediateRequest() only. */
    }
}

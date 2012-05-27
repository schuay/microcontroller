module HplDS1307C
{
    provides interface HplDS1307;

    uses interface Resource;
    uses interface I2CPacket<TI2CBasicAddr>;
}

#define I2C_ADDR (0b1101000)

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
    }

    async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
    }

    event void Resource.granted()
    {
        /* Ignored. We use immediateRequest() only. */
    }
}

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
    enum Operation {
        READ,
        WRITE,
        NONE,
    };

    static bool inProgress = FALSE;
    static enum Operation queuedOperation = NONE;
    static uint8_t *dataPtr;
    static uint8_t dataBuffer;
    static uint8_t dataSize;
    static uint8_t addressBuffer;

    command error_t HplDS1307.open(void)
    {
        return call Resource.immediateRequest();
    }

    command error_t HplDS1307.close(void)
    {
        bool progress;

        atomic {
            progress = inProgress;
        }

        if (progress) {
            return FAIL;
        }
        return call Resource.release();
    }

    command error_t HplDS1307.registerRead(uint8_t address)
    {
        bool owner = call Resource.isOwner();
        bool progress;

        atomic {
            progress = inProgress;
        }

        if (!owner || progress) {
            return FAIL;
        }

        atomic {
            inProgress = TRUE;
            addressBuffer = address;
            dataSize = 1;
            dataPtr = &dataBuffer;
            queuedOperation = READ;
        }

        return call I2CPacket.write(I2C_START | I2C_STOP, I2C_ADDR,
                            sizeof(addressBuffer), &addressBuffer);
    }

    command error_t HplDS1307.registerWrite(uint8_t address, uint8_t data)
    {
        bool owner = call Resource.isOwner();
        bool progress;

        atomic {
            progress = inProgress;
        }

        if (!owner || progress) {
            return FAIL;
        }

        atomic {
            inProgress = TRUE;
            addressBuffer = address;
            dataSize = 1;
            dataBuffer = data;
            dataPtr = &dataBuffer;
            queuedOperation = WRITE;
        }

        return call I2CPacket.write(I2C_START | I2C_STOP, I2C_ADDR,
                            sizeof(addressBuffer), &addressBuffer);
    }

    command error_t HplDS1307.bulkRead(ds1307_time_mem_t *data)
    {
        bool owner = call Resource.isOwner();
        bool progress;

        atomic {
            progress = inProgress;
        }

        if (!owner || progress) {
            return FAIL;
        }

        atomic {
            inProgress = TRUE;
            addressBuffer = REG_SECONDS;
            dataSize = sizeof(*data);
            dataPtr = (uint8_t *)data;
            queuedOperation = READ;
        }

        return call I2CPacket.write(I2C_START | I2C_STOP, I2C_ADDR,
                            sizeof(addressBuffer), &addressBuffer);
    }

    command error_t HplDS1307.bulkWrite(ds1307_time_mem_t *data)
    {
        bool owner = call Resource.isOwner();
        bool progress;

        atomic {
            progress = inProgress;
        }

        if (!owner || progress) {
            return FAIL;
        }

        atomic {
            inProgress = TRUE;
            addressBuffer = REG_SECONDS;
            dataSize = sizeof(*data);
            dataPtr = (uint8_t *)data;
            queuedOperation = WRITE;
        }

        return call I2CPacket.write(I2C_START | I2C_STOP, I2C_ADDR,
                            sizeof(addressBuffer), &addressBuffer);
    }

    async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
        switch (length) {
        case 1:
            signal HplDS1307.registerReadReady(*data);
            break;
        default:
            signal HplDS1307.bulkReadReady();
            break;
        }

        atomic {
            inProgress = FALSE;
        }
    }

    async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
    {
        enum Operation op;
        atomic {
            op = queuedOperation;
        }

        switch (op) {
        case READ:
            atomic {
                queuedOperation = NONE;
            }
            call I2CPacket.read(I2C_START | I2C_STOP, I2C_ADDR, dataSize, dataPtr);
            break;
        case WRITE:
            atomic {
                queuedOperation = NONE;
            }
            call I2CPacket.write(I2C_START | I2C_STOP, I2C_ADDR, dataSize, dataPtr);
            break;
        case NONE:
            switch (length) {
            case 1:
                signal HplDS1307.registerWriteReady();
                break;
            default:
                signal HplDS1307.bulkWriteReady();
                break;
            }

            atomic {
                inProgress = FALSE;
            }
            break;
        default:
            debug("Unexpected operation\r");
        }
    }

    event void Resource.granted()
    {
        /* Ignored. We use immediateRequest() only. */
    }
}

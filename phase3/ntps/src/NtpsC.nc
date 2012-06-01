#include <Atm128Uart.h>
#include <assert.h>

#define dprintf(...) do { \
        static in_addr_t destination = { .bytes {DESTINATION}}; \
        static uint8_t data[100]; \
        memset(data, 0, sizeof(data)); \
        snprintf((char *)data, 100, __VA_ARGS__); \
        call UdpSend.send(&destination, 50000UL, data, sizeof(data)); \
        } while (0);

module NtpsC
{
    uses interface Boot;
    uses interface UserInterface;
    uses interface GpsTimerParser;
    uses interface Rtc;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Time;

    uses interface UdpSend as UdpSend;
    uses interface UdpReceive as UdpReceive;
    uses interface SplitControl as Control;
    uses interface IpControl;
}

implementation
{
    static void addOffset(rtc_time_t *time);

    static rtc_time_t time = { 0, 51, 15, 1, 1, 2, 10 };
    static bool setToGPS = FALSE;
    static bool setToOffset = FALSE;

    event void Boot.booted(void)
    {
        in_addr_t cip = { .bytes {IP}};
        in_addr_t cnm = { .bytes {NETMASK}};
        in_addr_t cgw = { .bytes {GATEWAY}};

        debug("%s\r\n", __PRETTY_FUNCTION__);
        debug("Node ID %d\r\n", TOS_NODE_ID);

        call UserInterface.init();
        call Rtc.start(&time);
        call GpsTimerParser.startService();

        call Timer.startPeriodic(1000);

        /* Network setup. */
        call IpControl.setIp(&cip);
        call IpControl.setNetmask(&cnm);
        call IpControl.setGateway(&cgw);

        call Control.start();
    }

    event void UserInterface.setToGPSPressed(void)
    {
        debug("Set to GPS pressed.\r\n");
        setToGPS = TRUE;
    }

    event void UserInterface.setToOffsetPressed(void)
    {
        debug("Set to Offset pressed.\r\n");
        setToOffset = TRUE;
    }

    event void GpsTimerParser.newTimeDate(timedate_t newTimeDate)
    {
        debug("%s\r\n", __PRETTY_FUNCTION__);

        call UserInterface.setTimeGPS(newTimeDate);

        if (setToGPS) {
            time = newTimeDate;
            call Rtc.start(&time);
            setToGPS = FALSE;
        } else if (setToOffset) {
            time = newTimeDate;
            addOffset(&time);
            call Rtc.start(&time);
            setToOffset = FALSE;
        }
    }

#define HOURS_OFFSET (42)
#define HOURS_PER_DAY (24)
#define DAYS_PER_WEEK (7)
#define MONTHS_PER_YEAR (12)
    static void addOffset(rtc_time_t *timedate)
    {
        /* These deltas will be subtracted from time. */
        uint8_t delta_year = 0;
        uint8_t delta_month = 0;
        uint8_t delta_date = HOURS_OFFSET / HOURS_PER_DAY;
        uint8_t delta_hour = HOURS_OFFSET % HOURS_PER_DAY;

        /* Begin with days_in_month[0] == December so we can use
         * days_in_month[month % MONTHS_PER_YEAR]. */
        const uint8_t days_in_month[] = { 31, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 };

        /* Hours. */
        if (timedate->hours < delta_hour) {
            timedate->hours = HOURS_PER_DAY - (delta_hour - timedate->hours);
            delta_date++;
        } else {
            timedate->hours -= delta_hour;
        }

        assert(timedate->hours < 24);

        /* Day. */
        timedate->day = timedate->day - delta_date;
        if (timedate->day <= 0) {
            timedate->day += DAYS_PER_WEEK;
        }
        assert(timedate->day > 0 && timedate->day < 8);

        /* Date. */
        if (timedate->date <= delta_date) {
            delta_month++;
            timedate->date = days_in_month[(timedate->month - delta_month) % MONTHS_PER_YEAR] - (delta_date - timedate->date);

            /* TODO: use isLeapYear, and refactor date conversions into separate
             * module. */
            if ((timedate->year % 4 == 0) && ((timedate->year % 100 != 0) || (timedate->year %
                400 == 0))) {
                if (timedate->month - delta_month == 2) {
                    timedate->date++;
                }
            }
        } else {
            timedate->date -= delta_date;
        }
        assert(timedate->date > 0 && timedate->date < 32);

        /* Month. */
        timedate->month = timedate->month - delta_month;
        if (timedate->month <= 0) {
            timedate->month += MONTHS_PER_YEAR;
            delta_year++;
        }
        assert(timedate->month > 0 && timedate->month < 13);

        /* Year. */
        timedate->year -= delta_year;
    }

    event void Rtc.timeReady(void)
    {
        debug("%02d:%02d:%02d %02d.%02d.20%02d\r",
            time.hours, time.minutes, time.seconds,
            time.date, time.month, time.year);
        call UserInterface.setTimeRTC(time);
    }

    event void Timer.fired()
    {
        call Rtc.readTime(&time);
    }

    event void Control.stopDone(error_t error)
    {
        /* Ignored, won't happen. */
    }

    event void Control.startDone(error_t error)
    {
        debug("Ethernet started");
    }

    event void UdpSend.sendDone(error_t error)
    {
        debug("sendDone: %d\r", error);
    }

    struct ntp_packet_t
    {
        uint8_t mode :3;
        uint8_t version :3;
        uint8_t leap_indicator :2;
        uint8_t peer_stratum;
        uint8_t peer_interval;
        uint8_t peer_precision;
        uint32_t root_delay;
        uint32_t root_dispersion;
        uint32_t reference_id;
        uint64_t reference_timestamp;
        uint64_t originate_timestamp;
        uint64_t receive_timestamp;
        uint64_t transmit_timestamp;
    };

    /**
     * Converts hostlong from host to network byte order.
     */
    static uint32_t htonl(uint32_t hostlong)
    {
        /* TODO */
        return hostlong;
    }

    struct ntp_packet_t packet;
    event void UdpReceive.received(in_addr_t *srcIp, uint16_t srcPort, uint8_t *data, uint16_t len)
    {
        uint32_t timestamp = 0;

        if (len != sizeof(packet)) {
            return;
        }

        call Time.toNtpTimestamp(&timestamp, &time);

        memcpy(&packet, data, len);
        packet.mode = 0b100; /* Server. */
        packet.leap_indicator = 0b00; /* No warning. */
        packet.peer_stratum = 1; /* Primary server. */
        packet.peer_interval = 6;
        packet.peer_precision = -18; /* One microsend. */
        packet.reference_id = *((uint32_t *)"XXXX"); /* All starting with X reserved for development. */
        packet.originate_timestamp = packet.transmit_timestamp;
        packet.reference_timestamp = packet.receive_timestamp
                                   = packet.transmit_timestamp = htonl(timestamp); /* TODO: ensure we hit the seconds field. */

        call UdpSend.send(srcIp, srcPort, (uint8_t *)&packet, sizeof(packet));
    }
}

/**
 * Hpl implementation for KS0108 GLCD Display
 * @author:    Markus Hartmann e988811@student.tuwien.ac.at
 * @date:      01.02.2012
 * Based on an implementation of Andreas Hagmann
 */

#define KS0108_STATUS_BUSY          (0x80)    // (1)->LCD IS BUSY
#define KS0108_ON_CTRL              (0x3E)    // 0011111X: lcd on/off control
#define KS0108_ON_DISPLAY           (0x01)    //        DB0: turn display on
#define KS0108_START_LINE           (0xC0)    // 11XXXXXX: set lcd start line

#if MHZ == 8
#define KS0108_BUSY_WAIT_MICRO 1
#elif MHZ == 16
#define KS0108_BUSY_WAIT_MICRO 2
#else
#error "Unsupported clock rate. MHZ must be 8 or 16."
#endif

module HplKS0108P
{
  provides interface HplKS0108;
 
  uses interface GeneralIO as CS_0;
  uses interface GeneralIO as CS_1;
  uses interface GeneralIO as RS;
  uses interface GeneralIO as RW;
  uses interface GeneralIO as EN;
  uses interface GeneralIO as RST;

  uses interface GeneralIOPort as Data;

  uses interface BusyWait<TMicro,uint16_t>;  
}

implementation
{

  /************* PROTOTYPES **********/
  void init_HW(void);
  void reset(void);  
  void controller_select(const uint8_t controller);
  void busy_wait_controller(const uint8_t controller);
  
  command error_t HplKS0108.init(void){
    init_HW();

    call HplKS0108.controlWrite(0, KS0108_ON_CTRL|KS0108_ON_DISPLAY);
    call HplKS0108.controlWrite(1, KS0108_ON_CTRL|KS0108_ON_DISPLAY);

    call HplKS0108.controlWrite(0, KS0108_START_LINE);
    call HplKS0108.controlWrite(1, KS0108_START_LINE);
    return SUCCESS;
  }

  command uint8_t HplKS0108.controlRead(const uint8_t controller){
    uint8_t data;

    busy_wait_controller(controller);
    call Data.makeInput(0xFF);
    call RS.clr();
    call RW.set();
    call EN.set();
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);

    data = call Data.read();
    call EN.set();
    call Data.makeOutput(0xFF);
    return data;
  }

  command error_t HplKS0108.controlWrite(const uint8_t controller, const uint8_t data){
    busy_wait_controller(controller);

    call RS.clr();
    call RW.clr();
    call EN.set(); 
    call Data.makeOutput(0xFF);

    call Data.write(data);
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);
    call EN.clr();
    return SUCCESS;
  }

  command uint8_t HplKS0108.dataRead(const uint8_t controller){
    uint8_t data;
    busy_wait_controller(controller);
    call Data.makeInput(0xFF);
    call RS.set();
    call RW.set();

    /* dummy read */
    call EN.set(); 
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    
    data = call Data.read();
    /* read */
    call EN.clr(); 
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    
    call EN.set(); 
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    
    data = call Data.read();
    call EN.clr(); 
    return data;
  }

  command error_t HplKS0108.dataWrite(const uint8_t controller, const uint8_t data){
    busy_wait_controller(controller);
    call Data.write(data);
    call Data.makeOutput(0xFF);
    call RS.set();
    call RW.clr();
    call EN.set(); 
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO); 
    call EN.clr(); 
    
    return SUCCESS;
  }

  /************* PRIVATE *************/

  void init_HW(void)
  {
    call CS_0.set();
    call CS_1.set();
    call RS.clr();
    call RW.set();
    call EN.set();
    call RST.set();
    
    call CS_0.makeOutput();
    call CS_1.makeOutput();
    call RS.makeOutput();
    call RW.makeOutput();
    call EN.makeOutput();
    call RST.makeOutput();

    call Data.clear(0xFF);
    call Data.makeOutput(0xFF);
  }
  
  void reset(void)
  {
    call RST.set();
  }

  void controller_select(const uint8_t controller){
    switch (controller){
    case 0:
      call CS_1.clr();
      call CS_0.set();
      break;
    case 1:
      call CS_0.clr();
      call CS_1.set();
      break;
    default:
      break;
    }
  }

  void busy_wait_controller(const uint8_t controller){
    uint8_t data;
    controller_select(controller);
    call Data.set(0x00);
    call Data.makeInput(0xFF);
    call RS.clr();
    call RW.set();
    call EN.set();
    call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    


    data = call Data.read();
    while ((data = call Data.read()) & KS0108_STATUS_BUSY){
      call EN.clr();
      call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    
      call EN.set();
      call BusyWait.wait(KS0108_BUSY_WAIT_MICRO);    
    }
    call EN.clr();
    call RW.clr();
    call Data.makeOutput(0xFF);
  }

}

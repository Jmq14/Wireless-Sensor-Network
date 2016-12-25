
#include "IntData.h"

configuration IntDataAppC {} 
implementation { 
  
  components IntDataC, MainC, LedsC, new TimerMilliC();

	components ActiveMessageC;
  components new AMReceiverC(AM_MSG);
  components new AMSenderC(AM_MSG);

  IntDataC.Boot -> MainC;
  IntDataC.Leds -> LedsC;
  IntDataC.Timer -> TimerMilliC;

	IntDataC.Control -> ActiveMessageC;
  IntDataC.Receive -> AMReceiverC;
  IntDataC.AMPacket -> AMSenderC;
  IntDataC.Packet -> AMSenderC;
  IntDataC.AMSend -> AMSenderC;
}


#include "IntData.h"

configuration IntDataAppC {} 
implementation { 
  
  components IntDataC, MainC, LedsC;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;

	components ActiveMessageC;
  components PrintfC;
  components new AMSenderC(AM_MSG);
  components new AMReceiverC(AM_MSG);

  IntDataC.Boot -> MainC;
  IntDataC.Leds -> LedsC;
  IntDataC.Timer1 -> Timer1;
  IntDataC.Timer2 -> Timer2;

	IntDataC.Control -> ActiveMessageC;
	IntDataC.Packet -> AMSenderC;
  IntDataC.AMSend -> AMSenderC;
  IntDataC.AMPacket -> AMSenderC;
  IntDataC.Receive -> AMReceiverC;
}

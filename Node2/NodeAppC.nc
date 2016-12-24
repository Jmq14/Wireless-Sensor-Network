#include "node.h"

configuration NodeAppC {} 
implementation { 
  
    components NodeC, MainC, LedsC;
    components new TimerMilliC() as Timer1;

    components ActiveMessageC;
    components new AMSenderC(AM_MSG);
    components new AMReceiverC(AM_MSG);

    NodeC.Boot -> MainC;
    NodeC.Leds -> LedsC;
    NodeC.Timer1 -> Timer1;

    NodeC.Control -> ActiveMessageC;
    NodeC.Packet -> AMSenderC;
    NodeC.AMSend -> AMSenderC;
    NodeC.AMPacket -> AMSenderC;
    NodeC.Receive -> AMReceiverC;
}

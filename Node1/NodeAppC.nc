#include "node.h"

configuration NodeAppC {} 
implementation { 
  
    components NodeC, MainC, LedsC;

    components ActiveMessageC;
    components new AMSenderC(AM_MSG);
    components new AMReceiverC(AM_MSG);

    NodeC.Boot -> MainC;
    NodeC.Leds -> LedsC;

    NodeC.Control -> ActiveMessageC;
    NodeC.Packet -> AMSenderC;
    NodeC.AMSend -> AMSenderC;
    NodeC.AMPacket -> AMSenderC;
    NodeC.Receive -> AMReceiverC;
}


#include "Timer.h"
#include "IntData.h"

module IntDataC {
  uses {
  	interface SplitControl as Control;
    interface Receive;
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;

    interface AMSend;
    interface Packet;
    interface AMPacket;
  }
}
implementation {

	message_t packet;

	uint16_t integers[2000];
	bool listened[2000];

	uint32_t max = 0, min = 65535, sum = 0, average, median;
	uint16_t curSeq = 0;

	bool busy = FALSE;
	uint16_t toSend[100];
	uint16_t toSendCount = 0;
  
  event void Boot.booted() {
  	int i;
  	for (i = 0; i < 2000; ++i) {
			listened[i] = FALSE;
  	}
  	call Control.start();
  }

  event void Control.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer.startPeriodic(500);
		} else {
			call Control.start();
		}
  }

  event void Control.stopDone(error_t err) {}

  bool ifAllListened() {
		int i;
		for (i = 0; i < 2000; ++i) {
			if (listened[i] == FALSE) {
				return FALSE;
			}
		}
		return TRUE;
  }

	  task void sendFillData() {
		if (!busy) {
			intdata_msg_t* this_pkt = (intdata_msg_t*)(call Packet.getPayload(&packet, NULL));
			toSendCount--;
			this_pkt->sequence_number = toSend[toSendCount];
			this_pkt->random_integer = integers[this_pkt->sequence_number-1];
			if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(intdata_msg_t)) == SUCCESS) {
				busy = TRUE;
				call Leds.led0Toggle();
			}
		}
  }
	
  event void AMSend.sendDone(message_t* msg, error_t error) {
		if(&packet == msg) {
			busy = FALSE;
			if(toSendCount>0){
				post sendFillData();
			}
		}
	}

  event void Timer.fired() {
  	if (ifAllListened()) {
			call Timer.stop();
  	}
  }



  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(intdata_msg_t)) {
			intdata_msg_t* recv_pkt = (intdata_msg_t*)payload;
			call Leds.led2Toggle();

			curSeq = recv_pkt->sequence_number - 1;
			if (listened[curSeq] == FALSE) {
				listened[curSeq] = TRUE;
				integers[curSeq] = (uint16_t)recv_pkt->random_integer;
			}
			
		} else if (len == sizeof(filldata_msg_t)) {
			filldata_msg_t* recv_pkt = (filldata_msg_t*)payload;
			call Leds.led1Toggle();
			if(listened[recv_pkt->sequence_number-1]) {
				toSend[toSendCount] = recv_pkt->sequence_number;
				toSendCount++;
				post sendFillData();
			}
		}
		return msg;
  }
}

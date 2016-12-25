#include "Timer.h"
#include "Sense.h"

#define SAMPLING_FREQUENCY 100
#define NODE0 633
#define NODE1 622
#define NODE2 589

module SenseC {
  uses {
  	interface SplitControl as Control;
    interface Timer<TMilli>;
  	interface Packet;
  	interface AMSend;
  	interface AMPacket;
    interface Receive;
    interface Boot;
    interface Leds;
    interface Read<uint16_t> as ReadTemp;
    interface Read<uint16_t> as ReadHumid;
    interface Read<uint16_t> as ReadLight;
  }
}
implementation {
	message_t packet;
	bool busy = FALSE;

	uint16_t cur_temp = 0;
	uint16_t cur_humid = 0;
	uint16_t cur_light = 0;
	
	uint16_t counter = 0;
	uint16_t version = 0;
    uint16_t interval = 100;
  
  event void Boot.booted() {
  	call Control.start();
  }

  task void sendData() {
		if (!busy) {
			sense_msg_t* this_pkt = (sense_msg_t*)(call Packet.getPayload(&packet, NULL));
            counter ++;
			this_pkt->nodeID = -1;
			this_pkt->temp = cur_temp;
			this_pkt->humid = cur_humid;
			this_pkt->light = cur_light;
			this_pkt->seq = counter;
			this_pkt->time = call Timer.getNow();
			this_pkt->token = 0xAFADB0D9;
			this_pkt->version = version;
			this_pkt->interval = interval;
			
			if (interval <= 1) {
				call Leds.led0Toggle();
				call Control.stop();
			}
				
			if(call AMSend.send(NODE1, &packet, sizeof(sense_msg_t)) == SUCCESS) {
				busy = TRUE;
				call Leds.led0Toggle();
			}
		}
  }

  event void Timer.fired() {
    call ReadTemp.read();
    call ReadHumid.read();
    call ReadLight.read();
    post sendData();
  }

  event void ReadTemp.readDone(error_t result, uint16_t data) {
  	if (result == SUCCESS) {
		cur_temp = data;
  	}
  }

  event void ReadHumid.readDone(error_t result, uint16_t data) {
	 if (result == SUCCESS) {
		cur_humid = data;
     }
  }

  event void ReadLight.readDone(error_t result, uint16_t data) {
  	 if (result == SUCCESS) {
        cur_light = data;
     }
  }
  
  event void Control.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer.startPeriodic(interval);
		} else {
			call Control.start();
		}
  }

  event void Control.stopDone(error_t err) {}

  event void AMSend.sendDone(message_t* msg, error_t error) {
	if(&packet == msg) {
		busy = FALSE;
	}
  }

  task void changeFreq() {
  	if (busy) {
  		call Leds.led1Toggle();
  		call Timer.stop();
  		call Timer.startPeriodic(interval);
  	} else {
  		post changeFreq();
  	}
  }
 
  /* receive new interval */
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
  	if(call AMPacket.source(msg) == NODE0 && len == sizeof(sense_msg_t)) {
  		sense_msg_t* this_pkt = (sense_msg_t*)payload;
  		if (this_pkt->token != 0xAFADB0D9) {
  			return msg;
  		} else if (this_pkt->nodeID == 3) {
  			version = this_pkt->version;
  			interval = this_pkt->interval;
  			//post changeFreq();
  			call Timer.stop();
  			call Timer.startPeriodic(interval);
  		}
  	}
  	return msg;
}
}


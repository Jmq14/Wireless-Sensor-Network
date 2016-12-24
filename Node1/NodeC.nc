#include "Timer.h"
#include "node.h"

module NodeC {
  uses {
  	interface SplitControl as Control;
    interface Receive;
    interface Boot;
    interface Leds;
    interface Packet;
	interface AMPacket;
    interface AMSend;
  }
}
implementation {

	message_t packet;
	bool busy = FALSE;

    bool first_found = FALSE;
    bool second_found = FALSE;
    uint32_t first;
    uint32_t second;

	bool node2ok = FALSE;
	coord_msg_t node2;
	coord_msg_t node3;
	bool node3ok = FALSE;

	uint32_t max = 0, min = 65535, sum = 0, average = 0, median = 0;

	uint32_t p_pivot = 0;
	uint32_t c_pivot = 0;
  
    event void Boot.booted() {
      	call Control.start();
    }

  	task void sendResult() {
		result_msg_t* this_pkt = (result_msg_t*)(call Packet.getPayload(&packet, NULL));
		this_pkt->group_id = 18;
		this_pkt->max = max;
		this_pkt->min = min;
		this_pkt->sum = sum;
		this_pkt->average = average;
		this_pkt->median = median;

		call AMSend.send(0, &packet, sizeof(result_msg_t));
  	}

  	event void Control.startDone(error_t err) {
		if (err != SUCCESS) {
			call Control.start();
		}
  	}

  	event void Control.stopDone(error_t err) {}

  	task void sendMasterMsg2() {
		if (!busy) {
			master_msg_t* this_pkt = (master_msg_t*)(call Packet.getPayload(&packet, NULL));
			call Leds.led0Toggle();
			this_pkt->pivot = c_pivot;
			if(call AMSend.send(NODE_TWO, &packet, sizeof(master_msg_t)) == SUCCESS) {
				busy = TRUE;
			}
		}
  	}

    task void sendMasterMsg3() {
        if (!busy) {
            master_msg_t* this_pkt = (master_msg_t*)(call Packet.getPayload(&packet, NULL));
            call Leds.led0Toggle();
            this_pkt->pivot = c_pivot;
            if(call AMSend.send(NODE_THREE, &packet, sizeof(master_msg_t)) == SUCCESS) {
                busy = TRUE;
            }
        }
    }

  	event void AMSend.sendDone(message_t* msg, error_t error) {
		if(&packet == msg) {
			busy = FALSE;
		}
	}

    void handle_coord_msg(coord_msg_t* msg) {
        if(msg->is_first == TRUE){
            if(call AMPacket.source((message_t*)msg) == NODE_TWO){
                node2ok = TRUE;
                node2 = *msg;
                call Leds.led1Toggle();
            } else if (call AMPacket.source((message_t*)msg) == NODE_THREE) {
                node3ok = TRUE;
                node3 = *msg;
                call Leds.led2Toggle();
            }
            if (node2ok && node3ok) {
                if(node2.max > node3.max) max = node2.max;
                else max = node3.max;
                if(node2.min > node3.min) min = node3.min;
                else min = node2.min;
                sum = node2.sum + node3.sum;
                average = sum / 2000;
                c_pivot = node2.head;
                post sendMasterMsg2();
                post sendMasterMsg3();
                node2ok = FALSE;
                node3ok = FALSE;
            }
        } else {
            // TODO
            if(node2ok == FALSE && call AMPacket.source((message_t*)msg) == NODE_TWO){
                node2ok = TRUE;
                node2 = *msg;
                call Leds.led1Toggle();
            } else if (node3ok == FALSE && call AMPacket.source((message_t*)msg) == NODE_THREE) {
                node3ok = TRUE;
                node3 = *msg;
                call Leds.led2Toggle();
            }
            if (node2ok && node3ok) {
                int c_pos = node2.pos+node3.pos;
                if (c_pos > 1000) c_pivot = node2.head;
                else if (c_pos < 999) c_pivot = node3.tail;
                else if (c_pos == 999) {
                    first_found = TRUE;
                    first = p_pivot;
                    c_pivot = node3.tail;
                }else {
                    second_found = TRUE;
                    second = p_pivot;
                    c_pivot = node2.head;
                }
                if (first_found && second_found){
                    median = (first+second)/2;
                    post sendResult();
                } 
                else {
                    post sendMasterMsg2();
                    post sendMasterMsg3();
                    node2ok = FALSE;
                    node3ok = FALSE;
                }  
            }
        }
    }

  	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(ack_msg_t) && call AMPacket.source(msg) == 0) {
			ack_msg_t* recv_pkt = (ack_msg_t*)payload;
			if (recv_pkt->group_id == 18) {
				call Control.stop();
			}
		} else if (len == sizeof(coord_msg_t)) {
			coord_msg_t* recv_pkt = (coord_msg_t*)payload;
			handle_coord_msg(recv_pkt);
		}
		return msg;
  	}

  	
}

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
    interface Timer<TMilli> as Timer1;
  }
}
implementation {

	message_t packet;
	bool busy = FALSE;

	bool is_first = TRUE;

	uint16_t integers[1000];
	bool listened[1000];

	uint32_t max = 0, min = 65535, sum = 0;
	int head = 0;
    int tail = 999;

	uint32_t p_pivot = 0;
	uint32_t c_pivot = 0;
	uint32_t p_pos = 0;
	uint32_t c_pos = 0;
	uint8_t waiting_pkg = 0;

  
  event void Boot.booted() {
  	int i;
  	for (i = 0; i < 1000; ++i) {
			listened[i] = FALSE;
  	}
  	call Control.start();
  }


  	event void Control.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer1.startPeriodic(1000);
		} else {
			call Control.start();
		}
  	}

  	event void Control.stopDone(error_t err) {}

  	task void sendCoordMsg() {
		if (!busy) {
			coord_msg_t* this_pkt = (coord_msg_t*)(call Packet.getPayload(&packet, NULL));
			call Leds.led1Toggle();
			this_pkt->max = max;
			this_pkt->min = min;
			this_pkt->sum = sum;
			this_pkt->is_first = is_first;
			this_pkt->pivot = c_pivot;
			this_pkt->pos = c_pos;
			this_pkt->head = integers[head];
			this_pkt->tail = integers[tail];

			if(call AMSend.send(NODE_ONE, &packet, sizeof(coord_msg_t)) == SUCCESS) {
				busy = TRUE;
			}
		}
  	}

  	event void AMSend.sendDone(message_t* msg, error_t error) {
		if(&packet == msg) {
			busy = FALSE;
		}
	}

    void swap(int *x,int *y)
    {
       int temp;
       temp = *x;
       *x = *y;
       *y = temp;
    }

    // m~i-1 < pivot i~n >=pivot
	int partition(int list[],int m,int n, int pivot)
	{
	    int i,j;
	    if( m < n)
	    {
	        i = m;
	        j = n;
	        while(i <= j)
	        {
	            while((i <= n) && (list[i] < pivot))
	                i++;
	            while((j >= m) && (list[j] >= pivot))
	                j--;
	            if( i < j)
	                swap(&list[i],&list[j]);
	        }
	        return i;
	    }
	}

  	bool ifMeListened() {
		int i;
		for (i = 0; i < 1000; ++i) {
			if (listened[i] == FALSE) {
				return FALSE;
			}
		}
		return TRUE;
  	}


  	event void Timer1.fired() {
  		if (ifMeListened()) {
			call Timer1.stop();
			post sendCoordMsg();
			is_first = FALSE;
			//call Control.stop();
  		} else {
  			call Timer1.startPeriodic(1000);
  		}
  	}

  	int seq2index(uint16_t seq_num) {
  		return (int)((seq_num-2) / 2);
  	}

  	uint16_t index2seq(int index) {
  		return (uint16_t)(2*index+2);
  	}

  	void handle_master_msg(master_msg_t* msg) {
		c_pivot = msg->pivot;

		if (c_pivot > p_pivot) head = p_pos;
		if (c_pivot < p_pivot) tail = p_pos-1;
		c_pos = partition(integers ,head,tail,c_pivot);
		p_pos = c_pos;
		p_pivot = c_pivot;
		post sendCoordMsg();
  	}

  	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(intdata_msg_t)) {
			intdata_msg_t* recv_pkt = (intdata_msg_t*)payload;
			if (recv_pkt->sequence_number % 2==0) {
				int index = seq2index(recv_pkt->sequence_number);
				if (listened[index] == FALSE) {
					listened[index] = TRUE;
					integers[index] = (uint16_t)recv_pkt->random_integer;
					call Leds.led2Toggle();
				}
			}
		} else if (len == sizeof(master_msg_t) && call AMPacket.source(msg) == NODE_ONE) {
			master_msg_t* recv_pkt = (master_msg_t*)payload;
			handle_master_msg(recv_pkt);
		}
		return msg;
  	}

  	
}

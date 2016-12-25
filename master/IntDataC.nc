#include "printf.h"
#include "Timer.h"
#include "IntData.h"

module IntDataC {
  uses {
  	interface SplitControl as Control;
    interface Receive;
    interface Boot;
    interface Leds;
    interface Packet;
	interface AMPacket;
    interface AMSend;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
  }
}
implementation {

	message_t packet;
	bool busy = FALSE;

	bool timer2Opened = FALSE;

	uint16_t integers[2000];
	bool listened[2000];

	uint32_t max = 0, min = 65535, sum = 0, average = 0, median = 0;
	uint16_t curSeq = 0;
	uint16_t lackStack[500];
	int top;
  
    event void Boot.booted() {
      	int i;
      	for (i = 0; i < 2000; ++i) {
    			listened[i] = FALSE;
      	}
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

		printf("group_id: %u\nmax: %lu\nmin: %lu\nsum: %lu\naverage: %lu\nmedian: %lu\n", this_pkt->group_id, this_pkt->max, this_pkt->min, this_pkt->sum, this_pkt->average, this_pkt->median);

		call AMSend.send(0, &packet, sizeof(result_msg_t));
    }

    event void Control.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer1.startPeriodic(1000);
		} else {
			call Control.start();
		}
    }

  event void Control.stopDone(error_t err) {}

    task void sendLackSeq() {
		if (!busy) {
			filldata_msg_t* this_pkt = (filldata_msg_t*)(call Packet.getPayload(&packet, NULL));
			call Leds.led1Toggle();
			this_pkt->sequence_number = lackStack[top-1]+1;
			--top;
				
			if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(filldata_msg_t)) == SUCCESS) {
				busy = TRUE;
			}
		}
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
		if(&packet == msg) {
			busy = FALSE;
			if (top > 0) {
				post sendLackSeq();
			}
		}
	}

	bool ifLack(int k) {
		if (k < 1995) {
			return listened[k+1] || listened[k+2] || listened[k+3] || listened[k+4];
		} else {
			return listened[(k+1)%2000] || listened[(k+2)%2000] || listened[(k+3)%2000] || listened[(k+4)%2000];
		}
	}

    bool ifAllListened() {
		int i;
		bool flag = TRUE;

		top = 0;
		for (i = 0; i < 2000; ++i) {
			if (listened[i] == FALSE) {
				flag = FALSE;

				if (top < 500 && ifLack(i)) {
					lackStack[top] = i;
					top++;
				} else {
					return FALSE;
				}
			}
		}

		if (top > 0) {
			post sendLackSeq();
		}
		
		return flag;
    }

    void swap(uint32_t *x,uint32_t *y)
	{
	    int temp;
	    temp = *x;
	    *x = *y;
	    *y = temp;
	}

	int partition(uint32_t list[],int m,int n, int pivot)
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
	    return 0;
	}

	void calValue(){
		int pivot = -1;
	    int head = 0;
	    int tail = 2000 - 1 ;
	    int pos;
	    int median1 = -1;
	    int median2 = -1;
	    	    int tmp = 1000;
	    int median2_min;
	    while(head < tail){
	        int i = head;
	        while(integers[i]==pivot && i <= tail){
	            i++;
	        }
	        if (i == tail) {
	            median1 = pivot;
	            break;
	        }
	        else {
	            //printf("i=%d ",i);
	            pivot = integers[i];
	        }
	        //printf("pivot=%d\n",pivot);
	        pos = partition(integers, head, tail, pivot);
	        if (pos > 999) {
	            tail = pos;
	            continue;
	        }
	        else if (pos < 999) {
	            head = pos; 
	            continue;
	        }
	        else {
	            median1 = pivot;
	            break;
	        }
	    }

	    median2_min = integers[tmp];
	    for(;tmp<2000;tmp++){
	    	if(median2_min > integers[tmp] ) median2_min = integers[tmp];
	    }
	    
	    median2 = median2_min;
		median = (median1+median2)/2;
	}

	

    event void Timer1.fired() {
      	if (ifAllListened()) {
    		call Timer1.stop();
    		calValue();
    		if (timer2Opened == FALSE) {
    			timer2Opened = TRUE;
    			call Timer2.startPeriodic(10);
    		}
      		post sendResult();
    			//call Control.stop();
      	}
    }

    event void Timer2.fired() {
      	call Leds.led0Toggle();
    	post sendResult();
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
    	} else if (len == sizeof(ack_msg_t) && call AMPacket.source(msg) == 0) {
    		ack_msg_t* recv_pkt = (ack_msg_t*)payload;
    		if (recv_pkt->group_id == 18) {
    			call Timer2.stop();
    			call Control.stop();
    		}
    	}
    	return msg;
    }
}


#ifndef INTDATA_H
#define INTDATA_H

typedef nx_struct intdata_msg_t {
	nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
}intdata_msg_t;

typedef nx_struct result_msg_t {
	nx_uint8_t group_id;
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;
	nx_uint32_t average;
	nx_uint32_t median;
}result_msg_t;

typedef nx_struct ack_msg_t {
	nx_uint8_t group_id;
}ack_msg_t;

typedef nx_struct coord_msg_t {
	nx_uint8_t is_first;
	nx_uint32_t pivot;
	nx_uint32_t left;
	nx_uint32_t head;
	nx_uint32_t tail;
	nx_uint32_t pos;
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;	
}coord_msg_t;

typedef nx_struct master_msg_t {
	nx_uint32_t pivot;
}master_msg_t;

enum {
  	AM_MSG = 0,
  	NODE_ONE = 52,
	NODE_TWO = 53,
	NODE_THREE = 54,
};

#endif

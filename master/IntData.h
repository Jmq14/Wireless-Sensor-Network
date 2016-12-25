/*
 * Author: Wang Zhao
 * Create time: 2015/12/26 10:54
 */

#ifndef INTDATA_H
#define INTDATA_H

typedef nx_struct intdata_msg_t {
	nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
}intdata_msg_t;

typedef nx_struct filldata_msg_t {
	nx_uint16_t sequence_number;
}filldata_msg_t;

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

enum {
  AM_MSG = 0,
};

#endif

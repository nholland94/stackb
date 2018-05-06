#ifndef __INSTRUCTIONS_H__
#define __INSTRUCTIONS_H__

#include <stdint.h>

typedef uint8_t instr;

#define DROP1 0
#define DROP2 1
#define DROP3 2
#define DROPN 3
#define DUP1 4
#define DUP2 5
#define DUP3 6
#define DUPN 7
#define OVER 8
#define PICK 9
#define ROTL 10
#define ROTR 11
#define SWAP 12
#define ADD 32
#define SUB 33
#define MUL 34
#define DIV 35
#define PUSH1_INT 96
#define PUSH2_INT 97
#define PUSH3_INT 98
#define PUSHN_INT 99
#define PUSH1_FLOAT 100
#define PUSH2_FLOAT 101
#define PUSH3_FLOAT 102
#define PUSHN_FLOAT 103
#define PUSH1_QUOTE 104
#define PUSH2_QUOTE 105
#define PUSH3_QUOTE 106
#define PUSHN_QUOTE 107
#define PUSH1_QREF 108
#define PUSH2_QREF 109
#define PUSH3_QREF 110
#define PUSHN_QREF 111
#define CALL 128
#define KEEP1 129
#define KEEP2 130
#define KEEP3 131
#define IF 160

#endif

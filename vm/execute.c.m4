include(`m4/foreach.m4')dnl
include(`m4/instructions.m4')dnl
#include "execute.h"
#include "common.h"
#include <stdio.h>

#define ARITHMETIC_OPERATION(OP, T0, V0, T1, V1, TR, VR) {\
  if((T0) == (T1)) {\
    *(TR) = (T0);\
    if((T0) == VTAG_INTEGER) {\
      *(VR) = *(int32_t*)&(V0) OP *(int32_t*)&(V1);\
    } else if(T0 == VTAG_FLOAT) {\
      *(VR) = *(float*)&(V0) OP *(float*)&(V1);\
    }\
  } else if((T0) == VTAG_INTEGER && (T1) == VTAG_FLOAT) {\
    *(TR) = VTAG_FLOAT;\
    *(VR) = (float)*(int32_t*)&(V0) OP *(float*)&(V1);\
  } else if((T0) == VTAG_FLOAT && (T1) == VTAG_INTEGER) {\
    *(TR) = VTAG_FLOAT;\
    *(VR) = *(float*)&(V0) OP (float)*(int32_t*)&(V1);\
  }\
}

void execute(machine *m, bool cycle_enabled) {
  size_t call_depth = 1;
  size_t count, quote_size;

  // stack registers
  vtag qref_t, t0, t1, t2;
  word qref_v, v0, v1, v2;

  static void *instr_jump_table[256] = {
foreach(`instr', `instruction_names', `    &&instr,
')dnl
  };

  goto JUMP;
NEXT_CYCLE:
  if(!cycle_enabled || m->code.curr >= m->call_stack.top->code_end) goto EXIT_CALL;
  // printf("======\n");
  // print_machine(m);
JUMP:
  goto *instr_jump_table[read_code_byte(m)];

DROP1:
  count = 1;
  goto DROP_ROUTINE;
DROP2:
  count = 2;
  goto DROP_ROUTINE;
DROP3:
  count = 3;
  goto DROP_ROUTINE;
DROPN:
  count = read_code_word(m);
DROP_ROUTINE:
  check_underflow(m, count);
  stack_drop(m, count);
  goto NEXT_CYCLE;

DUP1:
  check_underflow(m, 1);
  check_overflow(m, 1);
  stack_read(m, 0, &t0, &v0);
  stack_push1(m, t0, v0);
  goto NEXT_CYCLE;

DUP2:
  check_underflow(m, 1);
  check_overflow(m, 2);
  stack_read(m, 0, &t0, &v0);
  stack_push2(m, t0, v0, t0, v0);
  goto NEXT_CYCLE;

DUP3:
  check_underflow(m, 1);
  check_overflow(m, 3);
  stack_read(m, 0, &t0, &v0);
  stack_push3(m, t0, v0, t0, v0, t0, v0);
  goto NEXT_CYCLE;

DUPN:
  count = read_code_word(m);
  check_underflow(m, 1);
  check_overflow(m, count);
  stack_read(m, 0, &t0, &v0);
  while(count-- > 0) stack_push1(m, t0, v0);
  goto NEXT_CYCLE;

OVER:
  check_underflow(m, 2);
  check_overflow(m, 1);
  stack_read(m, 1, &t0, &v0);
  stack_push1(m, t0, v0);
  goto NEXT_CYCLE;

PICK:
  check_underflow(m, 3);
  check_overflow(m, 1);
  stack_read(m, 2, &t0, &v0);
  stack_push1(m, t0, v0);
  goto NEXT_CYCLE;

ROTL:
  check_underflow(m, 3);
  stack_read(m, 0, &t0, &v0);
  stack_read(m, 1, &t1, &v1);
  stack_read(m, 2, &t2, &v2);
  stack_write(m, 0, t1, v1);
  stack_write(m, 1, t2, v2);
  stack_write(m, 2, t0, v0);
  goto NEXT_CYCLE;

ROTR:
  check_underflow(m, 3);
  stack_read(m, 0, &t0, &v0);
  stack_read(m, 1, &t1, &v1);
  stack_read(m, 2, &t2, &v2);
  stack_write(m, 0, t2, v2);
  stack_write(m, 1, t0, v0);
  stack_write(m, 2, t1, v1);
  goto NEXT_CYCLE;

SWAP:
  check_underflow(m, 2);
  stack_read(m, 0, &t0, &v0);
  stack_read(m, 1, &t1, &v1);
  stack_write(m, 0, t1, v1);
  stack_write(m, 1, t0, v0);
  goto NEXT_CYCLE;

ADD:
  check_underflow(m, 2);
  stack_pop1(m, &t0, &v0);
  stack_read(m, 0, &t1, &v1);
  ARITHMETIC_OPERATION(+, t0, v0, t1, v1, &t2, &v2);
  stack_write(m, 0, t2, v2);
  goto NEXT_CYCLE;

SUB:
  check_underflow(m, 2);
  stack_pop1(m, &t0, &v0);
  stack_read(m, 0, &t1, &v1);
  ARITHMETIC_OPERATION(-, t0, v0, t1, v1, &t2, &v2);
  stack_write(m, 0, t2, v2);
  goto NEXT_CYCLE;

MUL:
  check_underflow(m, 2);
  stack_pop1(m, &t0, &v0);
  stack_read(m, 0, &t1, &v1);
  ARITHMETIC_OPERATION(*, t0, v0, t1, v1, &t2, &v2);
  stack_write(m, 0, t2, v2);
  goto NEXT_CYCLE;

DIV:
  check_underflow(m, 2);
  stack_pop1(m, &t0, &v0);
  stack_read(m, 0, &t1, &v1);
  ARITHMETIC_OPERATION(/, t0, v0, t1, v1, &t2, &v2);
  stack_write(m, 0, t2, v2);
  goto NEXT_CYCLE;

PUSH3_INT:
  check_overflow(m, 3);
  read_code_word3(m, &v0, &v1, &v2);
  stack_push3(m, VTAG_INTEGER, v0, VTAG_INTEGER, v1, VTAG_INTEGER, v2);
  goto NEXT_CYCLE;

PUSH2_INT:
  check_overflow(m, 2);
  read_code_word2(m, &v0, &v1);
  stack_push2(m, VTAG_INTEGER, v0, VTAG_INTEGER, v1);
  goto NEXT_CYCLE;

PUSH1_INT:
  check_overflow(m, 1);
  read_code_word1(m, &v0);
  stack_push1(m, VTAG_INTEGER, v0);
  goto NEXT_CYCLE;

PUSHN_INT:
  count = read_code_word(m);
  check_overflow(m, count);
  while(count-- > 0) stack_push1(m, VTAG_INTEGER, read_code_word(m));
  goto NEXT_CYCLE;

PUSH3_FLOAT:
  check_overflow(m, 3);
  read_code_word3(m, &v0, &v1, &v2);
  stack_push3(m, VTAG_FLOAT, v0, VTAG_FLOAT, v1, VTAG_FLOAT, v2);
  goto NEXT_CYCLE;

PUSH2_FLOAT:
  check_overflow(m, 2);
  read_code_word2(m, &v0, &v1);
  stack_push2(m, VTAG_FLOAT, v0, VTAG_FLOAT, v1);
  goto NEXT_CYCLE;

PUSH1_FLOAT:
  check_overflow(m, 1);
  read_code_word1(m, &v0);
  stack_push1(m, VTAG_FLOAT, v0);
  goto NEXT_CYCLE;

PUSHN_FLOAT:
  count = read_code_word(m);
  while(count-- > 0) stack_push1(m, VTAG_FLOAT, read_code_word(m));
  goto NEXT_CYCLE;

PUSH3_QUOTE:
  check_overflow(m, 1);
  quote_size = read_code_word(m);
  stack_push1(m, VTAG_QREF, QREF_CONS((int32_t)(m->code.curr - m->code.base), count));
  m->code.curr = (void*)((uint8_t*)m->code.curr + quote_size);
PUSH2_QUOTE:
  check_overflow(m, 1);
  quote_size = read_code_word(m);
  stack_push1(m, VTAG_QREF, QREF_CONS((int32_t)(m->code.curr - m->code.base), quote_size));
  m->code.curr = (void*)((uint8_t*)m->code.curr + quote_size);
PUSH1_QUOTE:
  check_overflow(m, 1);
  quote_size = read_code_word(m);
  stack_push1(m, VTAG_QREF, QREF_CONS((int32_t)(m->code.curr - m->code.base), quote_size));
  m->code.curr = (void*)((uint8_t*)m->code.curr + quote_size);
  goto NEXT_CYCLE;

PUSHN_QUOTE:
  count = read_code_word(m);
  while(count-- > 0) {
    quote_size = read_code_word(m);
    stack_push1(m, VTAG_QREF, QREF_CONS((int32_t)(m->code.curr - m->code.base), quote_size));
    m->code.curr = (void*)((uint8_t*)m->code.curr + quote_size);
  }
  goto NEXT_CYCLE;

PUSH3_QREF:
  check_overflow(m, 3);
  read_code_word3(m, &v0, &v1, &v2);
  stack_push3(m, VTAG_QREF, v0, VTAG_QREF, v1, VTAG_QREF, v2);
  goto NEXT_CYCLE;

PUSH2_QREF:
  check_overflow(m, 2);
  read_code_word2(m, &v0, &v1);
  stack_push2(m, VTAG_QREF, v0, VTAG_QREF, v1);
  goto NEXT_CYCLE;

PUSH1_QREF:
  check_overflow(m, 1);
  read_code_word1(m, &v0);
  stack_push1(m, VTAG_QREF, v0);
  goto NEXT_CYCLE;

PUSHN_QREF:
  count = read_code_word(m);
  check_overflow(m, count);
  while(count-- > 0) {
    read_code_word1(m, &v0);
    stack_push1(m, VTAG_QREF, v0);
  }
  goto NEXT_CYCLE;

CALL:
  stack_pop1(m, &qref_t, &qref_v);
  if(qref_t != VTAG_QREF) panic("TYPE ERROR");
  call(m, qref_v, &call_depth);
  goto NEXT_CYCLE;

KEEP1:
  stack_pop2(m, &qref_t, &qref_v, &t0, &v0);
  if(qref_t != VTAG_QREF) panic("TYPE ERROR");
  push_call(m, qref_v);
  execute(m, true);
  stack_push1(m, t0, v0);
  goto NEXT_CYCLE;

KEEP2:
  stack_pop3(m, &qref_t, &qref_v, &t0, &v0, &t1, &v1);
  if(qref_t != VTAG_QREF) panic("TYPE ERROR");
  push_call(m, qref_v);
  execute(m, true);
  stack_push2(m, t1, v1, t0, v0);
  goto NEXT_CYCLE;

KEEP3:
  stack_pop4(m, &qref_t, &qref_v, &t0, &v0, &t1, &v1, &t2, &v2);
  if(qref_t != VTAG_QREF) panic("TYPE ERROR");
  push_call(m, qref_v);
  execute(m, true);
  stack_push3(m, t2, v2, t1, v1, t0, v0);
  goto NEXT_CYCLE;

IF:
  stack_pop3(m, &t0, &v0, &t1, &v1, &t2, &v2);
  if(t0 == VTAG_QREF || t1 != VTAG_QREF || t2 != VTAG_QREF) panic("TYPE ERROR");
  qref_v = VALUE_TRUTHY(t0, v0) ? v1 : v2;
  call(m, qref_v, &call_depth);
  goto NEXT_CYCLE;

NO_INSTR:
  panic("INVALID INSTRUCTION");

EXIT_CALL:
  m->code.curr = m->call_stack.top->code_return;
  m->call_stack.top--;
  call_depth--;
  if(call_depth > 0) goto NEXT_CYCLE;
}

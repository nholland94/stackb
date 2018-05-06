#ifndef __MACHINE_H__
#define __MACHINE_H__

#include <stddef.h>
#include "common.h"

typedef struct call_frame {
  void *code_start;
  void *code_end;
  void *code_return;
} call_frame;

// the tag and value stacks are always the same size
// so only the value stack cap is kept for overflow checks
typedef struct value_stack {
  vtag *tag_bot;
  vtag *tag_top;
  word *val_bot;
  word *val_top;
  word *val_cap;
} value_stack;

typedef struct call_stack {
  call_frame *bot;
  call_frame *top;
  call_frame *cap;
} call_stack;

typedef struct code_ref {
  void *base;
  void *curr;
  void *cap;
} code_ref;

typedef struct machine {
  value_stack stack;
  call_stack call_stack;
  code_ref code;
} machine;

ptrdiff_t code_ref_offset(code_ref*);

void print_stack(machine*);
void print_call_stack(machine*);
void print_machine(machine*);

static inline void check_underflow(machine *m, size_t count) {
  if(m->stack.val_top - (count - 1) < m->stack.val_bot)
    panic("STACK UNDERFLOW");
}

static inline void check_overflow(machine *m, size_t count) {
  if(m->stack.val_top + count >= m->stack.val_cap)
    panic("STACK_OVERFLOW");
}

static inline void stack_drop(machine *m, size_t count) {
  m->stack.tag_top -= count;
  m->stack.val_top -= count;
}

static inline void stack_read(machine *m, ptrdiff_t index, vtag *t, word *v) {
  *t = *(m->stack.tag_top - index);
  *v = *(m->stack.val_top - index);
}

static inline void stack_write(machine *m, ptrdiff_t index, vtag t, word v) {
  *(m->stack.tag_top - index) = t;
  *(m->stack.val_top - index) = v;
}

static inline void stack_push1(machine *m, vtag t0, word v0) {
  *(m->stack.tag_top + 1) = t0;
  *(m->stack.val_top + 1) = v0;
  m->stack.tag_top++;
  m->stack.val_top++;
}

static inline void stack_push2(machine *m, vtag t0, word v0, vtag t1, word v1) {
  *(m->stack.tag_top + 1) = t0;
  *(m->stack.val_top + 1) = v0;
  *(m->stack.tag_top + 2) = t1;
  *(m->stack.val_top + 2) = v1;
  m->stack.tag_top += 2;
  m->stack.val_top += 2;
}

static inline void stack_push3(machine *m, vtag t0, word v0, vtag t1, word v1, vtag t2, word v2) {
  *(m->stack.tag_top + 1) = t0;
  *(m->stack.val_top + 1) = v0;
  *(m->stack.tag_top + 2) = t1;
  *(m->stack.val_top + 2) = v1;
  *(m->stack.tag_top + 3) = t2;
  *(m->stack.val_top + 3) = v2;
  m->stack.tag_top += 3;
  m->stack.val_top += 3;
}

static inline void stack_pop1(machine *m, vtag *t0, word *v0) {
  *t0 = *(m->stack.tag_top);
  *v0 = *(m->stack.val_top);
  m->stack.tag_top--;
  m->stack.val_top--;
}

static inline void stack_pop2(machine *m, vtag *t0, word *v0, vtag *t1, word *v1) {
  *t0 = *(m->stack.tag_top);
  *v0 = *(m->stack.val_top);
  *t1 = *(m->stack.tag_top - 1);
  *v1 = *(m->stack.val_top - 1);
  m->stack.tag_top -= 2;
  m->stack.val_top -= 2;
}

static inline void stack_pop3(machine *m, vtag *t0, word *v0, vtag *t1, word *v1, vtag *t2, word *v2) {
  *t0 = *(m->stack.tag_top);
  *v0 = *(m->stack.val_top);
  *t1 = *(m->stack.tag_top - 1);
  *v1 = *(m->stack.val_top - 1);
  *t2 = *(m->stack.tag_top - 2);
  *v2 = *(m->stack.val_top - 2);
  m->stack.tag_top -= 3;
  m->stack.val_top -= 3;
}
static inline void stack_pop4(machine *m, vtag *t0, word *v0, vtag *t1, word *v1, vtag *t2, word *v2, vtag *t3, word *v3) {
  *t0 = *(m->stack.tag_top);
  *v0 = *(m->stack.val_top);
  *t1 = *(m->stack.tag_top - 1);
  *v1 = *(m->stack.val_top - 1);
  *t2 = *(m->stack.tag_top - 2);
  *v2 = *(m->stack.val_top - 2);
  *t3 = *(m->stack.tag_top - 3);
  *v3 = *(m->stack.val_top - 3);
  m->stack.tag_top -= 4;
  m->stack.val_top -= 4;
}

static inline byte read_code_byte(machine *m) {
  byte b = *(byte*)m->code.curr;
  m->code.curr = (void*)((byte*)m->code.curr + 1);
  return b;
}

static inline word read_code_word(machine *m) {
  word w = *(word*)m->code.curr;
  m->code.curr = (void*)((word*)m->code.curr + 1);
  return w;
}

static inline void read_code_word1(machine *m, word *v0) {
  *v0 = *(word*)m->code.curr;
  m->code.curr = (void*)((word*)m->code.curr + 1);
}

static inline void read_code_word2(machine *m, word *v0, word *v1) {
  *v0 = *(word*)m->code.curr;
  *v1 = *((word*)m->code.curr + 1);
  m->code.curr = (void*)((word*)m->code.curr + 2);
}

static inline void read_code_word3(machine *m, word *v0, word *v1, word *v2) {
  *v0 = *(word*)m->code.curr;
  *v1 = *((word*)m->code.curr + 1);
  *v2 = *((word*)m->code.curr + 2);
  m->code.curr = (void*)((word*)m->code.curr + 3);
}

static inline void replace_call(machine *m, qref qref) {
  void *quote_start = m->code.base + QREF_OFFSET(qref);
  m->call_stack.top->code_start = quote_start;
  m->call_stack.top->code_end = quote_start + QREF_LENGTH(qref);
  m->call_stack.top->code_return = m->code.curr;
  m->code.curr = quote_start;
}

static inline void push_call(machine *m, qref qref) {
  if(m->call_stack.top + 1 >= m->call_stack.cap)
    panic("CALL STACK OVERFLOW");

  void *quote_start = m->code.base + QREF_OFFSET(qref);
  m->call_stack.top++;
  m->call_stack.top->code_start = quote_start;
  m->call_stack.top->code_end = quote_start + QREF_LENGTH(qref);
  m->call_stack.top->code_return = m->code.curr;
  m->code.curr = quote_start;
}

static inline void call(machine *m, qref qref, size_t *call_depth) {
  if(m->code.curr == m->call_stack.top->code_end) {
    replace_call(m, qref);
  } else {
    push_call(m, qref);
    *call_depth += 1;
  }
}

#endif

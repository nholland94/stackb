#include "machine.h"
#include <stdio.h>

void print_stack(machine *m) {
  char str[20];

  for(size_t i = 0; m->stack.val_top - i >= m->stack.val_bot; i++) {
    value_to_string(*(m->stack.tag_top - i), *(m->stack.val_top - i), str);
    printf("  %s\n", str);
  }
}

// TODO
void print_call_stack(machine *m) {
  for(size_t i = 0; m->call_stack.top - i >= m->call_stack.bot; i++) {
    printf("  0x%04x 0x%04x 0x%04x\n",
        m->call_stack.top->code_start - m->code.base,
        m->call_stack.top->code_end - m->code.base,
        m->call_stack.top->code_return - m->code.base
    );
  }
}

void print_machine(machine *m) {
  printf("current instruction: 0x%02x - 0x%04x\n", *(byte*)m->code.curr, m->code.curr - m->code.base);
  printf("stack: %d\n", (int)(m->stack.val_top - m->stack.val_bot + 1));
  print_stack(m);
  printf("call stack: %d\n", (int)(m->call_stack.top - m->call_stack.bot + 1));
  print_call_stack(m);
}

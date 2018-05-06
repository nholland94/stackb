#include "common.h"
#include <stdio.h>
#include <stdlib.h>

void panic(char *msg) {
  printf("PANIC: %s\n", msg);
  exit(1);
}

void value_to_string(vtag t, word v, char str[20]) {
  if(t == VTAG_INTEGER) {
    sprintf(str, "%d", *(int32_t*)&v);
  } else if(t == VTAG_FLOAT) {
    sprintf(str, "%f", *(float*)&v);
  } else if(t == VTAG_QREF) {
    sprintf(str, "{0x%04x:0x%04x}", QREF_OFFSET(v), QREF_LENGTH(v));
  } else {
    sprintf(str, "<ERROR>");
  }
}


include(`m4/iter.m4')dnl
include(`m4/instructions.m4')dnl
#ifndef __INSTRUCTIONS_H__
#define __INSTRUCTIONS_H__

#include <stdint.h>

typedef uint8_t instr;

define(`value', `0')dnl
foreach(`instr', `instruction_names',
  `ifelse(NO_INSTR, instr, `', ``#'define INSTR_`'instr value
')`'define(`value', eval(value + 1))')dnl

#endif

#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>

typedef uint8_t byte;
typedef uint32_t word;
typedef byte instr;
typedef byte vtag;
typedef word qref;

#define VTAG_INTEGER 0x01
#define VTAG_FLOAT   0x02
#define VTAG_QREF    0x03

#define QREF_OFFSET(Q)      (((Q) & 0xffff0000) >> 16)
#define QREF_LENGTH(Q)      ((Q) & 0x0000ffff)
#define QREF_CONS(OFF, LEN) ((((OFF) & 0xffff) << 16) | ((LEN) & 0xffff))

#define IMPLICIT_CAST(T, V) (*(T*)&(V))
#define VALUE_TRUTHY(T, V) (\
     ((T) == VTAG_FLOAT && (*(float*)&(V)) > 0.0f)\
  || ((T) == VTAG_INTEGER && (*(int32_t*)&(V)) > 0)\
)

void panic(char*);
void value_to_string(vtag, word, char[20]);

#endif

include(`m4/iter.m4')dnl
include(`m4/literals.m4')dnl
divert(`-1')
define(`instruction_data', patsubst(include(`data/instructions.txt'), `
', ``,'' `'))
define(`instruction_names', quote(map(`instr_data_row', `instruction_data', `arg1(patsubst(instr_data_row, ` ', `,'))')))
divert`'dnl

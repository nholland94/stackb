include(`m4/instructions.m4')dnl
include(`m4/iter.m4')dnl
include(`m4/join.m4')dnl
include(`m4/literals.m4')dnl
include(`m4/take.m4')dnl
open Core_kernel
open Stdint

let pp_uint32 = Uint32.printer
let pp_uint16 = Uint16.printer

type uint = uint32
[@@deriving show]

type qref = uint16 * uint16
[@@deriving show]

define(`param_type_name', `ifelse($1, `qlit', `t list', `$1')')dnl
type t = 
foreach(`instr_data', `instruction_data', `dnl
define(`instr_data', quote(patsubst(instr_data, ` ', `, ')))dnl
define(`instr_id', arg1(instr_data))dnl
define(`instr_params', quote(shift(instr_data)))dnl
ifelse(instr_id, `NO_INSTR', `',
  `  | instr_id ifelse(quote(instr_params), `', `',
    `of ifelse(regexp(quote(instr_params), `^\*', `1'), `1',
      `param_type_name(patsubst(instr_params, `^\*', `')) list',
      `join(` * ', map(`param', `instr_params', `param_type_name(param)'))')')
')dnl
')dnl
[@@deriving show]

define(`param_byte_fn', `ifelse($1, `qlit', `bytes_of_instr', `bytes_of_`'$1')')dnl
let rec bytes_of_instr = function
foreachi(`instr_value', `instr_data', `instruction_data', `dnl
define(`instr_data', quote(patsubst(instr_data, ` ', `, ')))dnl
define(`instr_id', arg1(instr_data))dnl
define(`instr_params', quote(shift(instr_data)))dnl
define(`instr_hex', format(`%02x', instr_value))dnl
define(`instr_byte', `RQ`'\x`'instr_hex`'RQ')dnl
ifelse(instr_id, `NO_INSTR', `',
  `  | instr_id ifelse(quote(instr_params), `',
    `-> [instr_byte]',
    `define(`arg_ids', take(nargs(instr_params), `x, y, z'))(join(`, ', arg_ids)) -> instr_byte :: ifelse(regexp(quote(instr_params), `^\*', `1'), `1',
      `List.concat (List.`m'ap arg1(arg_ids) `~f:'param_byte_fn(regexp(quote(instr_params), `^\*\(.*\)', `\1')))',
      `(join(` @ ', map2(`param', `instr_params', `arg_id', `arg_ids',
        `param_byte_fn(param) arg_id')))')')
')`'dnl
')dnl

open Core_kernel
open Stdint

type uint = uint32
[@@deriving show]
type qref = uint16 * uint16
[@@deriving show]

type t = 
  | DROP1 
  | DROP2 
  | DROP3 
  | DROPN of uint
  | DUP1 
  | DUP2 
  | DUP3 
  | DUPN of uint
  | OVER 
  | PICK 
  | ROTL 
  | ROTR 
  | SWAP 
  | ADD 
  | SUB 
  | MUL 
  | DIV 
  | PUSH1_INT of int
  | PUSH2_INT of int * int
  | PUSH3_INT of int * int * int
  | PUSHN_INT of int list
  | PUSH1_FLOAT of float
  | PUSH2_FLOAT of float * float
  | PUSH3_FLOAT of float * float * float
  | PUSHN_FLOAT of float list
  | PUSH1_QUOTE of t list
  | PUSH2_QUOTE of t list * t list
  | PUSH3_QUOTE of t list * t list * t list
  | PUSHN_QUOTE of t list list
  | PUSH1_QREF of qref
  | PUSH2_QREF of qref * qref
  | PUSH3_QREF of qref * qref * qref
  | PUSHN_QREF of qref list
  | CALL 
  | KEEP1 
  | KEEP2 
  | KEEP3 
  | IF 
[@@deriving show]

let rec bytes_of_instr = function
  | DROP1 -> ['\x00']
  | DROP2 -> ['\x01']
  | DROP3 -> ['\x02']
  | DROPN (x) -> '\x03' :: (bytes_of_uint x)
  | DUP1 -> ['\x04']
  | DUP2 -> ['\x05']
  | DUP3 -> ['\x06']
  | DUPN (x) -> '\x07' :: (bytes_of_uint x)
  | OVER -> ['\x08']
  | PICK -> ['\x09']
  | ROTL -> ['\x0a']
  | ROTR -> ['\x0b']
  | SWAP -> ['\x0c']
  | ADD -> ['\x20']
  | SUB -> ['\x21']
  | MUL -> ['\x22']
  | DIV -> ['\x23']
  | PUSH1_INT (x) -> '\x60' :: (bytes_of_int x)
  | PUSH2_INT (x, y) -> '\x61' :: (bytes_of_int x @ bytes_of_int y)
  | PUSH3_INT (x, y, z) -> '\x62' :: (bytes_of_int x @ bytes_of_int y @ bytes_of_int z)
  | PUSHN_INT (x) -> '\x63' :: List.concat (List.map x ~f:bytes_of_int)
  | PUSH1_FLOAT (x) -> '\x64' :: (bytes_of_float x)
  | PUSH2_FLOAT (x, y) -> '\x65' :: (bytes_of_float x @ bytes_of_float y)
  | PUSH3_FLOAT (x, y, z) -> '\x66' :: (bytes_of_float x @ bytes_of_float y @ bytes_of_float z)
  | PUSHN_FLOAT (x) -> '\x67' :: List.concat (List.map x ~f:bytes_of_float)
  | PUSH1_QUOTE (x) -> '\x68' :: (bytes_of_instr x)
  | PUSH2_QUOTE (x, y) -> '\x69' :: (bytes_of_instr x @ bytes_of_instr y)
  | PUSH3_QUOTE (x, y, z) -> '\x6a' :: (bytes_of_instr x @ bytes_of_instr y @ bytes_of_instr z)
  | PUSHN_QUOTE (x) -> '\x6b' :: List.concat (List.map x ~f:bytes_of_instr)
  | PUSH1_QREF (x) -> '\x6c' :: (bytes_of_qref x)
  | PUSH2_QREF (x, y) -> '\x6d' :: (bytes_of_qref x @ bytes_of_qref y)
  | PUSH3_QREF (x, y, z) -> '\x6e' :: (bytes_of_qref x @ bytes_of_qref y @ bytes_of_qref z)
  | PUSHN_QREF (x) -> '\x6f' :: List.concat (List.map x ~f:bytes_of_qref)
  | CALL -> ['\x80']
  | KEEP1 -> ['\x81']
  | KEEP2 -> ['\x82']
  | KEEP3 -> ['\x83']
  | IF -> ['\xa0']

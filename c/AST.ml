open Core_kernel

type t =
  | W of string (* word *)
  | I of int    (* int *)
  | F of float  (* float *)
  | Q of t list (* quote *)
[@@deriving show]

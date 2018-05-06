open Core_kernel
open Bigarray

type ast =
  | W of string   (* word *)
  | I of int      (* int *)
  | F of float    (* float *)
  | Q of ast list (* quote *)
[@@deriving show]

type 'qref instr =
  | DROP1
  | DROP2
  | DROP3
  | DROPN of int
  | DUP1
  | DUP2
  | DUP3
  | DUPN of int
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
  | PUSH1_QUOTE of 'qref instr list
  | PUSH2_QUOTE of 'qref instr list * 'qref instr list
  | PUSH3_QUOTE of 'qref instr list * 'qref instr list * 'qref instr list
  | PUSHN_QUOTE of 'qref instr list list
  | PUSH1_QREF of 'qref
  | PUSH2_QREF of 'qref * 'qref
  | PUSH3_QREF of 'qref * 'qref * 'qref
  | PUSHN_QREF of 'qref list
  | CALL
  | KEEP1
  | KEEP2
  | KEEP3
  | IF
[@@deriving show]

type tag =
  | Inline
[@@deriving show]

let ignore _ = ()
let cons_pair x y = (x, y)

let rec take_count_while ls ~f =
  match ls with
    | []     -> (0, [])
    | h :: t ->
        if not (f h) then (0, h :: t) else
          let (c, t) = take_count_while t ~f in
          (c + 1, t)
let rec take_map_while ls ~f =
  match ls with
    | []     -> ([], [])
    | h :: t ->
        (match f h with
          | Some x -> let (r, t) = take_map_while t ~f in (x :: r, t)
          | None   -> ([], h :: t))

let parser =
  let open Angstrom in
  let is_whitespace = function ' ' | '\n' -> true | _ -> false in
  let is_alpha = function 'a' .. 'z' | 'A' .. 'Z' -> true | _ -> false in
  let is_numeric = function '0' .. '9' -> true | _ -> false in
  let ws = skip_while is_whitespace in
  let ws1 = satisfy is_whitespace *> skip_while is_whitespace in
  let wspad p = ws *> p <* ws in
  let sequence =
    fix (fun sequence ->
      let item = choice
        [ take_while1 is_alpha >>| (fun x -> W x);
          lift2 (fun l r -> F (float_of_string (l ^ "." ^ r)))
            (take_while1 is_numeric <* char '.')
            (take_while1 is_numeric);
          take_while1 is_numeric >>| (fun x -> I (int_of_string x));
          char '[' *> sequence <* char ']' >>| (fun x -> Q x) ]
      in
      wspad (sep_by ws1 item))
  in
  let definition = wspad (lift2 cons_pair (take_while is_alpha <* ws <* string "::" <* ws) sequence) in
  many1 definition <* ws <* end_of_input

let dynamic_instr instr1 instr2 instr3 instrn = function
  | n when n <= 0 -> raise (Invalid_argument "dynamic_instr")
  | 1             -> instr1
  | 2             -> instr2
  | 3             -> instr3
  | n             -> instrn n
let polymorphic_instr instr1 instr2 instr3 instrn = function
  | []        -> raise (Invalid_argument "polymorphic_instr")
  | [x]       -> instr1 x
  | [x; y]    -> instr2 x y
  | [x; y; z] -> instr3 x y z
  | ls        -> instrn ls

let drop_instr = dynamic_instr DROP1 DROP2 DROP3 (fun n -> DROPN n)
let dup_instr = dynamic_instr DUP1 DUP2 DUP3 (fun n -> DUPN n)
let push_int_instr =
  polymorphic_instr
    (fun x     -> PUSH1_INT x)
    (fun x y   -> PUSH2_INT (x, y))
    (fun x y z -> PUSH3_INT (x, y, z))
    (fun ls    -> PUSHN_INT ls)
let push_float_instr =
  polymorphic_instr
    (fun x     -> PUSH1_FLOAT x)
    (fun x y   -> PUSH2_FLOAT (x, y))
    (fun x y z -> PUSH3_FLOAT (x, y, z))
    (fun ls    -> PUSHN_FLOAT ls)
let push_quote_instr =
  polymorphic_instr
    (fun x     -> PUSH1_QUOTE x)
    (fun x y   -> PUSH2_QUOTE (x, y))
    (fun x y z -> PUSH3_QUOTE (x, y, z))
    (fun ls    -> PUSHN_QUOTE ls)
let push_qref_instr =
  polymorphic_instr
    (fun x     -> PUSH1_QREF x)
    (fun x y   -> PUSH2_QREF (x, y))
    (fun x y z -> PUSH3_QREF (x, y, z))
    (fun ls    -> PUSHN_QREF ls)

let rec lower_ast = function
  | h :: t -> lower_ast_node h t
  | []     -> []
and lower_ast_node node tail =
  match node with
  (* ???
    | Ref r      ->
        let (values, tail) = r :: take_map_while (function Ref x -> Some x | _ -> None) tail in
        push_qref_instr values :: lower_ast tail
  *)
    | I v ->
        let (values, tail) = take_map_while tail ~f:(function I x -> Some x | _ -> None) in
        push_int_instr (v :: values) :: lower_ast tail
    | F v ->
        let (values, tail) = take_map_while tail ~f:(function F x -> Some x | _ -> None) in
        push_float_instr (v :: values) :: lower_ast tail
    | Q q ->
        let (quotes, tail) = take_map_while tail ~f:(function Q x -> Some (lower_ast x) | _ -> None) in
        push_quote_instr (lower_ast q :: quotes) :: lower_ast tail
    | W "drop" ->
        let (c, tail) = take_count_while tail ~f:((=) (W "drop")) in
        drop_instr (c + 1) :: lower_ast tail
    | W "dup" ->
        let (c, tail) = take_count_while tail ~f:((=) (W "dup")) in
        dup_instr (c + 1) :: lower_ast tail
    | W "over"  -> OVER :: lower_ast tail
    | W "pick"  -> PICK :: lower_ast tail
    | W "rotl"  -> ROTL :: lower_ast tail
    | W "rotr"  -> ROTR :: lower_ast tail
    | W "swap"  -> SWAP :: lower_ast tail
    | W "add"   -> ADD :: lower_ast tail
    | W "sub"   -> SUB :: lower_ast tail
    | W "mul"   -> MUL :: lower_ast tail
    | W "div"   -> DIV :: lower_ast tail
    | W "call"  -> CALL :: lower_ast tail
    | W "keep"  -> KEEP1 :: lower_ast tail
    | W "keep2" -> KEEP2 :: lower_ast tail
    | W "keep3" -> KEEP3 :: lower_ast tail
    | W _       -> failwith "TODO"

let compile_word get_byte =
  [get_byte 3; get_byte 2; get_byte 1; get_byte 0]

let compile_int n = compile_word (fun i ->
  let shift = i * 8 in
  Char.of_int_exn (((0xff lsl shift) land n) lsr shift))
let compile_float f = compile_word (fun i ->
  failwith "TODO")

let rec compile_instr compile_qref = function
  | DROP1                 -> ['\x00']
  | DROP2                 -> ['\x01']
  | DROP3                 -> ['\x02']
  | DROPN n               -> '\x03' :: compile_int n
  | DUP1                  -> ['\x04']
  | DUP2                  -> ['\x05']
  | DUP3                  -> ['\x06']
  | DUPN n                -> '\x07' :: compile_int n
  | OVER                  -> ['\x08']
  | PICK                  -> ['\x09']
  | ROTL                  -> ['\x0a']
  | ROTR                  -> ['\x0b']
  | SWAP                  -> ['\x0c']
  | ADD                   -> ['\x20']
  | SUB                   -> ['\x21']
  | MUL                   -> ['\x22']
  | DIV                   -> ['\x23']
  | PUSH1_INT x           -> '\x60' :: compile_int x
  | PUSH2_INT (x, y)      -> '\x61' :: (compile_int x @ compile_int y)
  | PUSH3_INT (x, y, z)   -> '\x62' :: (compile_int x @ compile_int y @ compile_int z)
  | PUSHN_INT ls          -> '\x63' :: (compile_int (List.length ls) @ List.fold_right ls ~f:(fun n acc -> compile_int n @ acc) ~init:[])
  | PUSH1_FLOAT x         -> '\x64' :: compile_float x
  | PUSH2_FLOAT (x, y)    -> '\x65' :: (compile_float x @ compile_float y)
  | PUSH3_FLOAT (x, y, z) -> '\x66' :: (compile_float x @ compile_float y @ compile_float z)
  | PUSHN_FLOAT ls        -> '\x67' :: (compile_int (List.length ls) @ List.fold_right ls ~f:(fun n acc -> compile_float n @ acc) ~init:[])
  | PUSH1_QUOTE x         -> '\x68' :: compile_quote compile_qref x
  | PUSH2_QUOTE (x, y)    -> '\x69' :: (compile_quote compile_qref x @ compile_quote compile_qref y)
  | PUSH3_QUOTE (x, y, z) -> '\x6a' :: (compile_quote compile_qref x @ compile_quote compile_qref y @ compile_quote compile_qref z)
  | PUSHN_QUOTE ls        -> '\x6b' :: (compile_int (List.length ls) @ List.fold_right ls ~f:(fun n acc -> compile_quote compile_qref n @ acc) ~init:[])
  | PUSH1_QREF x          -> '\x6c' :: compile_qref x
  | PUSH2_QREF (x, y)     -> '\x6d' :: (compile_qref x @ compile_qref y)
  | PUSH3_QREF (x, y, z)  -> '\x6e' :: (compile_qref x @ compile_qref y @ compile_qref z)
  | PUSHN_QREF ls         -> '\x6f' :: (compile_int (List.length ls) @ List.fold_right ls ~f:(fun n acc -> compile_qref n @ acc) ~init:[])
  | CALL                  -> ['\x80']
  | KEEP1                 -> ['\x81']
  | KEEP2                 -> ['\x82']
  | KEEP3                 -> ['\x83']
  | IF                    -> ['\xa0']
and compile_quote compile_qref instrs =
  let bytes = compile compile_qref instrs in
  compile_int (List.length bytes) @ bytes
and compile compile_qref instrs = List.concat (List.map instrs ~f:(compile_instr compile_qref))

let parse_and_compile source =
  let definitions =
    match Angstrom.parse_string parser source with
      | Ok x      -> x
      | Error err -> failwith ("parsing error: " ^ err)
  in
  let ast_table = Hashtbl.create (module String) ~growth_allowed:true ~size:1024 () in
  List.iter definitions ~f:(fun (key, data) -> ignore (Hashtbl.add ast_table ~key ~data));
  let bytecode_table = Hashtbl.map ast_table ~f:lower_ast in
  let tag_table = Hashtbl.map bytecode_table ~f:tag_bytecode_definition in
  (* expand_and_collect expands inline definitions and collects remaining references in a new hashtable *)
  let program_table = expand_and_collect bytecode_table (Hashtbl.find table "main") in
  let qref_table = Hashtbl.create (module String) ~growth_allowed:false ~size:(Hashtbl.length program_table) in
  ignore (Hashtbl.fold program_table
    ~init:0
    ~f:(fun ~key ~data offset ->
      let size = ? in
      Hashtbl.add tbl ~key ~data:(offset, size);
      offset + size));
  let dereferenced_program_table = Hashtbl.map program_table ~f:(lower_qrefs qref_table) in
  let entry_qref = Hashtbl.find qref_table "main" in
  let bytes = compile compile_qref (flatten_table dereferenced_program_table) in
  let buffer = Array1.create Char C_layout (List.length bytes) in
  List.iteri bytes ~f:(fun i b -> Array1.set buffer i b);
  (entry_qref, buffer)

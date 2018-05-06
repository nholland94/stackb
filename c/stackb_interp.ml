exception TypeError
exception StackError

type value =
  | Int of int
  | Float of float
  | Quote of instr list
and instr =
  | Push of value
  | Dup
  | Swap
  | Over
  | Pick
  | Rot
  | Drop
  | Drop2
  | Drop3
  | Add
  | Sub
  | Mul
  | Div
  | If
  | Call
  | Keep
  | Keep2

let show_value = function
  | Int n   -> string_of_int n
  | Float f -> string_of_float f
  | Quote _ -> "<Quote>"
let show_instr = function
  | Push v -> "Push " ^ show_value v
  | Dup    -> "Dup"
  | Swap   -> "Swap"
  | Over   -> "Over"
  | Pick   -> "Pick"
  | Rot    -> "Rot"
  | Drop   -> "Drop"
  | Drop2  -> "Drop2"
  | Drop3  -> "Drop3"
  | Add    -> "Add"
  | Sub    -> "Sub"
  | Mul    -> "Mul"
  | Div    -> "Div"
  | If     -> "If"
  | Call   -> "Call"
  | Keep   -> "Keep"
  | Keep2  -> "Keep2"
let show_stack stack = List.map show_value stack |> String.concat " "

let value_gt_int value x =
  match value with
    | Int n   -> n > x
    | Float n -> n > (float_of_int x)
    | _       -> raise TypeError

let apply_arithmetic int_fn float_fn a b =
  match (a, b) with
    | (Int an, Int bn)     -> Int (int_fn an bn)
    | (Float an, Float bn) -> Float (float_fn an bn)
    | (Int an, Float bn)   -> Float (float_fn (float_of_int an) bn)
    | (Float an, Int bn)   -> Float (float_fn an (float_of_int bn))
    | _                    -> raise TypeError

let rec interpret_instr stack instr =
  match (instr, stack) with
    | (Push x, st)                           -> x :: st
    | (Dup, x :: st)                         -> x :: x :: st
    | (Swap, a :: b :: st)                   -> b :: a :: st
    | (Over, a :: b :: st)                   -> b :: a :: b :: st
    | (Pick, a :: b :: c :: st)              -> c :: a :: b :: c :: st
    | (Rot, a :: b :: c :: st)               -> b :: c :: a :: st
    | (Drop, _ :: st)                        -> st
    | (Drop2, _ :: _ :: st)                  -> st
    | (Drop3, _ :: _ :: _ :: st)             -> st
    | (Add, a :: b :: st)                    -> apply_arithmetic (+) (+.) a b :: st
    | (Sub, a :: b :: st)                    -> apply_arithmetic (-) (-.) a b :: st
    | (Mul, a :: b :: st)                    -> apply_arithmetic ( * ) ( *. ) a b :: st
    | (Div, a :: b :: st)                    -> apply_arithmetic (/) (/.) a b :: st
    | (Call, Quote q :: st)                  -> execute st q
    | (Call, _ :: _)                         -> raise TypeError
    | (Keep, Quote q :: a :: st)             -> a :: execute st q
    | (Keep, _ :: _ :: _)                    -> raise TypeError
    | (Keep2, Quote q :: a :: b :: st)       -> a :: b :: execute st q
    | (Keep2, _ :: _ :: _)                   -> raise TypeError
    | (If, cond :: Quote a :: Quote b :: st) -> execute st (if value_gt_int cond 0 then a else b)
    | (If, _ :: _ :: _ :: _)                 -> raise TypeError
    | _                                      -> raise StackError
and execute stack = List.fold_left interpret_instr stack

let execute_program = execute []

(* calculate 4^10:
 *
 * 4 [4 mul]
 * [
 *   1 swap sub
 *   [drop3]
 *   [[dup rot call swap] keep2 over call]
 *   pick if 
 * ]
 * 10 over call
 *)
let loop_program =
  [ Push (Int 4);
    Push (Quote [Push (Int 4); Mul]);
    Push (Quote
      [ Push (Int 1);
        Swap;
        Sub;
        Push (Quote [Drop3]);
        Push (Quote
          [ Push (Quote [Dup; Rot; Call; Swap]);
            Keep2;
            Over;
            Call ]);
        Pick;
        If ]);
    Push (Int 10);
    Over;
    Call ]

open Angstrom
open AST

let is_whitespace = function
  | ' ' | '\n' -> true
  | _          -> false
let is_alpha = function
  | 'a' .. 'z'
  | 'A' .. 'Z' -> true
  | _          -> false
let is_numeric = function
  | '0' .. '9' -> true
  | _          -> false

let ws = skip_while is_whitespace
let ws1 = satisfy is_whitespace *> skip_while is_whitespace
let wspad p = ws *> p <* ws

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
let definition = wspad (lift2 cons_pair (take_while is_alpha <* ws <* string "::" <* ws) sequence)
let program = many1 definition <* ws <* end_of_input

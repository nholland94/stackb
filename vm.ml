type id = string
type _type =
  | TAbstr of _type * _type
  | TNat
  | TBool
type constant = _type * int

type abstr = id * _type * exp
and exp =
  | L of abstr
  | U of abstr
  | A of exp * exp
  | I of id
  | C of constant

type value =
  | ValC of constant
  | ValL of closure
  | ValU of rec_closure
and env = (id * value) list
and closure = abstr * env * env
and rec_closure = abstr * env

(* ((Lx:int.Lf:int->int.fx)0)(Ly:int.y) *)
let test_exp =
  A (
    A (
      L ("x", TNat,
        L ("f", TAbstr (TNat, TNat),
          A (I "f", I "x")))'
      C (TNat, 0)),
    L ("y", TNat, I "y"))

let rec eval l_env g_env = function
  | A (l, r) -> apply (eval l) (eval r)
  | L abstr  -> ValL (abstr, [], g_env)
  | U abstr  -> ValU (abstr, g_env)
  | I id     -> lookup id env
  | C const  -> ValC const
and apply (lv, lt) (rv, tv) =
  match lv with
    | ValL ((arg_id, arg_type, exp), l_env, g_env) ->
        (if arg_type <> rt then raise TypeError (arg_type, rt);
        eval ((arg_id, (rv, rt)) :: l_env) g_env exp

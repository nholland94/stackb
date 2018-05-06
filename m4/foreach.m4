divert(`-1')
include(`m4/quote.m4')
define(`foreach', `pushdef(`$1')_foreach($@)popdef(`$1')')
define(`_arg1', `$1')
define(`_foreach', `ifelse(quote($2), `', `',
  `define(`$1', `_arg1($2)')$3`'$0(`$1', `shift($2)', `$3')')')
divert`'dnl

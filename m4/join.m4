divert(`-1')
define(`join', ``$2'_$0(`$1', shift($@))')
define(`_join',
  `ifelse(`$#', `2', `', ``$1$3'$0(`$1', shift(shift($@)))')')
divert`'dnl

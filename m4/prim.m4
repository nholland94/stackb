divert(`-1')
define(`nargs', `$#')
define(`echo', `$*')
define(`echoquote', `$@')
define(`arg1', `$1')
define(`quote', `ifelse(`$#', `0', `', ``$*'')')
divert`'dnl

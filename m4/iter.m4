include(`m4/prim.m4')dnl
divert(`-1')

define(`foreach', `pushdef(`$1')_foreach($@)popdef(`$1')')
define(`_foreach', `ifelse(quote($2), `', `',
  `define(`$1', `arg1($2)')$3`'$0(`$1', `shift($2)', `$3')')')

define(`foreach2', `pushdef(`$1')pushdef(`$3')_foreach2($@)popdef(`$3')popdef(`$3')')
define(`_foreach2', `ifelse(quote($2), `',
  `ifelse(quote($4), `', `', `errprint(`foreach2 macro called with lists of different lengths')')',
  `ifelse(quote($4), `', `errprint(`foreach2 macro called with lists of different lengths')',
    `define(`$1', `arg1($2)')define(`$3', `arg1($4)')$5`'$0(`$1', `shift($2)', `$3', `shift($4)', `$5')')')')

define(`foreachi', `pushdef(`$1')define(`$1', `0')_foreachi($@)popdef(`$1')')
define(`_foreachi', `foreach(`$2', `$3', `$4`'define(`$1', eval($1 + 1))')')

define(`map', `pushdef(`_map_acc')define(`_map_acc', `')_map($@)_map_acc`'popdef(`_map_acc')')
define(`_map', `foreach(`$1', `$2',
  `define(`_map_acc', quote(_map_acc`'ifelse(quote(_map_acc), `', `', `, ')`'$3))')')

define(`map2', `pushdef(`_map_acc')define(`_map_acc', `')_map2($@)_map_acc`'popdef(`_map_acc')')
define(`_map2', `foreach2(`$1', `$2', `$3', `$4',
  `define(`_map_acc', quote(_map_acc`'ifelse(quote(_map_acc), `', `', `, ')`'$5))')')

divert`'dnl

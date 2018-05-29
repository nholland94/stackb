divert(`-1')

define(`take', `pushdef(`_take_acc')define(`_take_acc', `')_take($@)`'popdef(`_take_acc')')
define(`_take', `ifelse(`$1', `0', `_take_acc',
  `ifelse(quote($2), `', `errprint(`take macro called with too many requested elements')',
    `define(`_take_acc', `quote'(_take_acc`'ifelse(quote(_take_acc), `', `', `, ')`'arg1($2)))$0(eval(`$1' - 1), `shift($2)')')')')

divert`'dnl

#!/usr/bin/env tclsh

package require textutil::expander

proc lambda {argl body} {
    set name [info level 0]
    proc $name $argl $body
    set name
}

proc cache_proc {id body} {
  variable impl_id "__cache_proc_impl_$id" {}
  proc $impl_id {} $body
  proc $id {} "
    global __proc_cache
    if {!\[info exists __proc_cache($id)]} {
      set __proc_cache($id) \[$impl_id]
    }
    return \[set __proc_cache($id)]
  "
}

proc hex_to_dec {hex} {
  variable dec
  scan $hex %x dec
  return $dec
}

proc dec_to_hex {dec} {
  return [format %X $dec]
}

proc read_file {filename} {
  variable fd
  variable file_data

  set fd [open $filename]
  set file_data [read $fd]
  close $fd

  return $file_data
}

proc collect_instructions {data} {
  variable instrs
  variable val 0
  variable val_hint

  foreach line [split $data "\n"] {
    if {[regexp {^# *0x([0-9a-f]{2})} $line -> val_hint]} {
      if {[hex_to_dec $val_hint] != $val} {
        puts stderr "VALUE_HINT MISMATCH: 0x[dec_to_hex $val_hint] expected, actual value is 0x[dec_to_hex $val]"
      }
    } elseif {$line != {}} {
      set instrs($val) $line
      incr val
    }
  }

  return [array get instrs]
}

cache_proc instructions {
  return [collect_instructions [read_file "data/instructions.txt"]]
}

cache_proc instruction_count {
  variable instrs
  array set instrs [instructions]
  return [array size instrs]
}

cache_proc non_reserved_instructions {
  return [filter [instructions] {name val} {expr [$name != "RESERVED"]}]
}

proc map_instructions {fn} {
  variable accum {}
  variable instrs
  array set instrs [instructions]

  for {variable val 0} {$val < [instruction_count]} {incr val} {
    append accum [$fn [set instrs($val)] $val]
  }

  return $accum
}

::textutil::expander tmpl
tmpl setbrackets <@ @>
puts stdout [tmpl expand [read stdin]]

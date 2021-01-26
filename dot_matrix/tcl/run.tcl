
# 0 = Note  1 = Warning  2 = Error  3 = Failure  4 = Fatal
set BreakOnAssertion 3
 
# Collect command line arguments $1 to $9
proc collectCmdLineArgs {} {
  set flags ""
  for {set i 1} {$i < 10} {incr i} {
    global $i
    if {[info exists $i]} {
      set flags [subst "$flags \$$i"]
    }
  }
  return $flags
}
 
proc loadTb {tbEnt {flags ""}} {
 
  # If the design already is loaded
  if {[runStatus] != "nodesign" && [find instances -bydu -nodu $tbEnt] == "/$tbEnt"} {
    restart -force
  } else {
    vsim -gui -onfinish stop -msgmode both dot_matrix_sim.$tbEnt
   
    # If flags contains "nowave"
    if {[lsearch -exact $flags nowave] != -1} {
      # Close wave window
      noview wave
    } else {
      # Open wave window
      do wave.do
      view wave
    }
  }
}
 
# Run testbench with entity <tbEnt> from the dot_matrix_sim lib
proc runTb {tbEnt {flags ""}} {
  loadTb $tbEnt $flags
  run -all
}
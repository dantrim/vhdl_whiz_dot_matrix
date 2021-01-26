
source tcl/run.tcl
 
# Callback function triggered on simulation break
onbreak {
 
  # If the testbench stopped before the "finish;" keyword
  set stopReason [lindex [runStatus -full] end]
  if {$stopReason ne {$finish}} {
    set tbStatus "Failed"
    set regressionStatus $tbStatus
  }
 
  resume
}
 
# Find all run.do files
set runFiles [glob -type f */run.do */*/run.do]
 
set allStatus ""
set regressionStatus "OK"
 
# Run all testbenches
foreach f $runFiles {
  set tbStatus "OK"
  puts "Running $f"
  do $f nowave
  set name [string range $f 0 end-7]
  lappend allStatus "$name: $tbStatus"
}
 
# Print the results
puts ""
puts "** Regression test completed **"
puts ""
foreach s $allStatus {
  puts $s
}
puts ""
puts "Regression test: $regressionStatus"
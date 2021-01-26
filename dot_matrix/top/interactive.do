source tcl/run.tcl
 
loadTb top_tb
 
# Set this signal in the TB to disable self-checking behavior
force /interactive true
 
proc tx {str} {
 
  set clockPeriod [examine /sim_constants/clock_period]
  set baudRate [examine -radix unsigned /constants/baud_rate]
 
  # The estimated time in ns used for transmitting a character
  set txTime [expr (1e9 / $baudRate) * 10]
 
  # The time it takes to check the output after writing one character
  set characterTestTime [examine -radix unsigned /character_test_time]
 
  foreach char [split $str ""] {
   
    # Get the ASCII code for this character
    set code [scan $char %c]
    if {$code < 0 || $code > 127} {
      return -code error "Char '$code' is out of range 0-127"
    }
     
    # Transmit another character to the DUT
    force -deposit /uart_tx_start '1'
    force -deposit /uart_tx_data 10#$code
    run $clockPeriod
    force -deposit /uart_tx_start '0'
    run $txTime ns
    run $characterTestTime
  }
}
 
run -all
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TB
add wave -noupdate /uart_tb/clk
add wave -noupdate /uart_tb/rst
add wave -noupdate /uart_tb/tx_rx
add wave -noupdate /uart_tb/rx_data
add wave -noupdate /uart_tb/rx_valid
add wave -noupdate /uart_tb/rx_stop_bit_error
add wave -noupdate /uart_tb/tx_start
add wave -noupdate /uart_tb/tx_data
add wave -noupdate /uart_tb/tx_busy
add wave -noupdate -divider UART_TX
add wave -noupdate /uart_tb/UART_TX/clk_counter
add wave -noupdate /uart_tb/UART_TX/state
add wave -noupdate /uart_tb/UART_TX/data_sampled
add wave -noupdate /uart_tb/UART_TX/bit_counter
add wave -noupdate -divider UART_RX
add wave -noupdate /uart_tb/UART_RX/state
add wave -noupdate /uart_tb/UART_RX/clk_counter
add wave -noupdate /uart_tb/UART_RX/rx_p1
add wave -noupdate /uart_tb/UART_RX/bit_counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7610762 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 224
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {7989842 ps}

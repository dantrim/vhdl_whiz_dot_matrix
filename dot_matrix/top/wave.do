onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/DUT/clk
add wave -noupdate /top_tb/DUT/rst_button
add wave -noupdate /top_tb/DUT/uart_rx
add wave -noupdate /top_tb/DUT/uart_tx
add wave -noupdate /top_tb/DUT/led_1
add wave -noupdate /top_tb/DUT/led_2
add wave -noupdate /top_tb/DUT/led_3
add wave -noupdate /top_tb/DUT/led_4
add wave -noupdate /top_tb/DUT/led_5
add wave -noupdate /top_tb/DUT/rows
add wave -noupdate /top_tb/DUT/cols
add wave -noupdate /top_tb/DUT/rst
add wave -noupdate /top_tb/DUT/uart_rx_data
add wave -noupdate /top_tb/DUT/uart_rx_valid
add wave -noupdate /top_tb/DUT/uart_rx_stop_bit_error
add wave -noupdate /top_tb/DUT/uart_tx_busy
add wave -noupdate /top_tb/DUT/char_buf_data_out
add wave -noupdate /top_tb/DUT/char_rom_addr
add wave -noupdate /top_tb/DUT/led8x8
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {35659 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 175
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {33614 ps}

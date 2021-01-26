onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider DUT
add wave -noupdate /led_controller_8x8_tb/DUT/clk
add wave -noupdate /led_controller_8x8_tb/DUT/rst
add wave -noupdate /led_controller_8x8_tb/DUT/led8x8
add wave -noupdate /led_controller_8x8_tb/DUT/rows
add wave -noupdate /led_controller_8x8_tb/DUT/cols
add wave -noupdate /led_controller_8x8_tb/DUT/pulse_counter
add wave -noupdate /led_controller_8x8_tb/DUT/row_counter
add wave -noupdate -divider VC
add wave -noupdate /led_controller_8x8_tb/VC/touched_leds
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {18888531112 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 299
configure wave -valuecolwidth 40
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
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {21617008949 ps}

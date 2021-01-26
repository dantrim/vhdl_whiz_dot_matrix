onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /reset_tb/DUT/clk
add wave -noupdate /reset_tb/DUT/rst_in
add wave -noupdate /reset_tb/DUT/rst_out
add wave -noupdate -radix hexadecimal /reset_tb/DUT/counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10665085 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 242
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
WaveRestoreZoom {0 ps} {106050 ns}

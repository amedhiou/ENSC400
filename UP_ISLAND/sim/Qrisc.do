onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /e/uut/bus_mr
add wave -noupdate -format Logic /e/uut/bus_mw
add wave -noupdate -format Literal -radix hexadecimal /e/uut/bus_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/bus_data_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/bus_data_inbus
add wave -noupdate -format Logic -radix hexadecimal /e/uut/bus_nready
add wave -noupdate -divider Qrisc
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/clk
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/reset
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/reboot
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/freeze
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/i_nready
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/d_nready
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/i_busy
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/d_busy
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/interrupt_vector
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/i_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/i_data_inbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/d_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/d_data_inbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/d_data_outbus
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/mem_read
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/mem_write
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/mem_isbyte
add wave -noupdate -format Logic -radix hexadecimal /e/uut/uut/mem_ishalf
add wave -noupdate -divider Rfile
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/ra
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/a_out
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/rb
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/b_out
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/rd1
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/d1_in
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/reg_in
add wave -noupdate -format Literal -radix hexadecimal /e/uut/uut/regfile/reg_out
add wave -noupdate -divider BUS
add wave -noupdate -format Logic -radix hexadecimal /e/uut/localbus/m1_mr
add wave -noupdate -format Logic -radix hexadecimal /e/uut/localbus/m1_mw
add wave -noupdate -format Literal -radix hexadecimal /e/uut/localbus/m1_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/localbus/m1_data_inbus
add wave -noupdate -format Literal -radix hexadecimal /e/uut/localbus/m1_data_outbus
add wave -noupdate -format Logic -radix hexadecimal /e/uut/localbus/m1_busy
add wave -noupdate -format Logic -radix hexadecimal /e/uut/localbus/m1_nready
add wave -noupdate -format Literal /e/uut/localbus/c1_op
add wave -noupdate -format Literal /e/uut/localbus/c2_op
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {275 ns} 0}
configure wave -namecolwidth 227
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
WaveRestoreZoom {244 ns} {249 ns}

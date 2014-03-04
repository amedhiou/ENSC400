onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /e/dt/clock_out
add wave -noupdate -divider {Qrisc Processor}
add wave -noupdate -format Logic /e/clk
add wave -noupdate -format Logic /e/reset
add wave -noupdate -format Logic /e/freeze
add wave -noupdate -format Logic /e/reboot
add wave -noupdate -format Logic /e/i_nready
add wave -noupdate -format Logic /e/d_nready
add wave -noupdate -format Logic /e/i_busy
add wave -noupdate -format Logic /e/d_busy
add wave -noupdate -format Literal -radix hexadecimal /e/interrupt_vector
add wave -noupdate -format Literal -radix hexadecimal /e/i_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/i_data_inbus
add wave -noupdate -format Literal -radix hexadecimal /e/i_data_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/d_addr_outbus
add wave -noupdate -format Literal -radix hexadecimal /e/d_data_inbus
add wave -noupdate -format Literal -radix hexadecimal /e/d_data_outbus
add wave -noupdate -format Logic /e/dmem_read
add wave -noupdate -format Logic /e/dmem_write
add wave -noupdate -format Logic /e/dmem_isbyte
add wave -noupdate -format Logic /e/dmem_ishalf
add wave -noupdate -format Logic /e/suspend
add wave -noupdate -format Logic /e/ext_bp_request
add wave -noupdate -format Logic /e/dbg_enable
add wave -noupdate -format Logic /e/imem_write
add wave -noupdate -format Logic /e/imem_read
add wave -noupdate -divider RFILE
add wave -noupdate -format Literal -radix unsigned /e/uut/regfile/ra
add wave -noupdate -format Literal -radix hexadecimal /e/uut/regfile/a_out
add wave -noupdate -format Literal -radix unsigned /e/uut/regfile/rb
add wave -noupdate -format Literal -radix hexadecimal /e/uut/regfile/b_out
add wave -noupdate -format Literal -radix unsigned /e/uut/regfile/rd1
add wave -noupdate -format Literal -radix hexadecimal /e/uut/regfile/d1_in
add wave -noupdate -divider Memhandle
add wave -noupdate -format Literal /e/uut/mpath/the_memhandle/mem_baddr
add wave -noupdate -format Literal /e/uut/mpath/the_memhandle/read_data
add wave -noupdate -format Literal /e/uut/mpath/the_memhandle/stored_data
add wave -noupdate -format Literal /e/uut/mpath/the_memhandle/smdr_in
add wave -noupdate -format Literal /e/uut/mpath/the_memhandle/data_out
add wave -noupdate -divider IRAM
add wave -noupdate -format Logic -radix hexadecimal /e/imem/clk
add wave -noupdate -format Logic -radix hexadecimal /e/imem/rdn
add wave -noupdate -format Logic -radix hexadecimal /e/imem/wrn
add wave -noupdate -format Literal -radix hexadecimal /e/imem/address
add wave -noupdate -format Literal -radix hexadecimal /e/imem/data_in
add wave -noupdate -format Literal -radix hexadecimal /e/imem/data_out
add wave -noupdate -divider DRAM
add wave -noupdate -format Logic /e/dmem/clk
add wave -noupdate -format Logic /e/dmem/wrn
add wave -noupdate -format Logic /e/dmem/rdn
add wave -noupdate -format Literal -radix hexadecimal /e/dmem/address
add wave -noupdate -format Literal -radix hexadecimal /e/dmem/data_in
add wave -noupdate -format Literal -radix hexadecimal /e/dmem/data_out
add wave -noupdate -divider DEBUG
add wave -noupdate -format Logic /e/dt/clk
add wave -noupdate -format Logic /e/dt/reset
add wave -noupdate -format Logic /e/dt/wrn
add wave -noupdate -format Literal -radix hexadecimal /e/dt/address
add wave -noupdate -format Literal -radix ascii /e/dt/data_in
add wave -noupdate -format Logic /e/dt/clock_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {309 ns} 0}
configure wave -namecolwidth 150
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
WaveRestoreZoom {265 ns} {291 ns}

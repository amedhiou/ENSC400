vsim -novopt E 
add wave -radix hex {sim:/e/clk} {sim:/e/resetn} {sim:/e/r } {sim:/e/g } {sim:/e/b } {sim:/e/gray}  
restart -f ; run 300 ns


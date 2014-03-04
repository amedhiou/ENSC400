restart -f
run 5 ns 
# Load Memory Content
mem load -format mti -startaddress 0 -infile Imem.mem /e/imem/ram_array
mem load -format mti -startaddress 0 -infile Dmem.mem /e/dmem/ram_array

# Run simulation
run 1000000 ns

# Save Memory
#mem save -format mti -addressradix hex -dataradix hex -startaddress 0 -endaddress 8 -outfile results.mem /e/imem/ram_array


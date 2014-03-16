# Simple script for compiling a vhdl file for simulation
# fcampi@sfu.ca

# Cleaning the work folder (This should not be done if compiling incrementally)
\rm -rf work

# Creating and mapping to logic name work the local work library
vlib work
vmap work work

# Compiling the VHDL code for simulation
vcom -novopt ../../REG/vhdl/REG.vhd 
vcom -novopt ../../SRAM/vhdl/SRAM.vhd
vcom -novopt ../../COUNTER/vhdl/counter.vhd
vlog -novopt ../../FIFO/vlog/fifo1.v
vcom -novopt ../vhdl/BUS.vhd
vcom -novopt ../vhdl/Top_BUS.vhd
vcom -novopt ../vhdl/BUS_M_4S.vhd



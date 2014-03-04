# Simple script for compiling a vhdl file for simulation
# fcampi@sfu.ca

# Cleaning the work folder (This should not be done if compiling incrementally)
\rm -rf work

# Creating and mapping to logic name work the local work library
vlib work
vmap work work

# Compiling the VHDL code for simulation
vcom -novopt ../../vhdl/SRAM.vhd
vcom -novopt ../../vhdl/PSRAM.vhd
vcom -novopt ../../vhdl/tb_SRAM.vhd
vcom -novopt ../../vhdl/tb_PSRAM.vhd


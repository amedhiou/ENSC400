#! /bin/tcsh -f

echo "QRISC Compilation"
echo ""
echo ""

vmap work work

setenv my_path /ensc/grad1/cmc-16/ENSC400/UP_ISLAND/vhdl

# Compile the Qrisc processor here if you see it fit
echo "Compile Qrisc based up island"
vcom -novopt -quiet ../../../BUS/vhdl/*.vhd
vcom -novopt -quiet ../../../SRAM/vhdl/SRAM.vhd
vcom -novopt -quiet ../../../REG/vhdl/REG.vhd
vcom -novopt -quiet ../../vhdl/ubus.vhd
vcom -novopt -quiet ../../vhdl/Debug_Tool.vhd
vcom -novopt -quiet ../../vhdl/up_island.vhd
vcom -novopt -quiet ../../vhdl/tb_upisland.vhd

echo ""
echo ""


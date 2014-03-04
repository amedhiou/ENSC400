#! /bin/tcsh -f

echo "QRISC Compilation"
echo ""
echo ""

setenv my_path /ensc/grad1/cmc-16/ENSC400/Qrisc/vhdl/5.9

\rm -rf work
vlib work

echo "QRISC PROCESSOR COMPILATION" 
 
echo "- Configuration files"
vcom -quiet $my_path/CORE/xi_menu.vhd 
vcom -quiet $my_path/CORE/xi_basic.vhd

echo "------------------------ XiRisc Core"   
echo ""
echo "- Miscellaneous"
vcom -quiet $my_path/CORE/xi_isa32.vhd
vcom -quiet $my_path/CORE/xi_components.vhd
vcom -quiet $my_path/CORE/xi_definitions.vhd
echo ""
echo "- Control Logic"
vcom -novopt -quiet $my_path/CORE/xi_decodeop32.vhd
vcom -quiet $my_path/CORE/xi_decodepc.vhd
vcom -quiet $my_path/CORE/xi_hazards.vhd
vcom -quiet $my_path/CORE/xi_pcbvgen.vhd
vcom -quiet $my_path/CORE/xi_addrcheck.vhd
vcom -quiet $my_path/CORE/xi_control.vhd
echo ""

echo "- Data Path"
vcom -quiet $my_path/CORE/xi_alu_simple.vhd
vcom -quiet $my_path/CORE/xi_shifter.vhd
vcom -quiet $my_path/CORE/xi_multiplier.vhd
vcom -quiet $my_path/CORE/xi_memhandle.vhd
vcom -quiet $my_path/CORE/xi_mainchannel.vhd
echo ""

echo "- Register File"
vcom -quiet $my_path/CORE/xi_rfile.vhd
echo ""

echo "- SCC Coprocessor"
vcom -quiet $my_path/CORE/xi_scc.vhd
echo ""

echo "- FPU Coprocessor"
vcom -quiet $my_path/CORE/xi_fpu.vhd
echo ""

echo "- DBG Coprocessor"
vcom -quiet $my_path/CORE/xi_dbg.vhd
echo ""

echo "- Breaks Verification System"
vcom -quiet $my_path/CORE/xi_verify.vhd
echo ""

echo "- XiRisc Core"
vcom -quiet $my_path/CORE/xi_core.vhd 
echo ""



# Create Floorplan (45 nm)

# floorPlan -su <aspectRatio> [<stdCellDensity> [<coreToLeft> <coreToBottom> <coreToRight> <coreToTop>]]

floorPlan -d 360 300  4 4 4 4   

editPin -fixedPin 1 -snap TRACK -side Top -unit TRACK -layer 2 -spreadType center -spacing 20.0 \
    -pin {CLK reset BUS_NREADY {BUS_DATA_INBUS[0]} {BUS_DATA_INBUS[1]} {BUS_DATA_INBUS[2]} {BUS_DATA_INBUS[3]} {BUS_DATA_INBUS[4]} {BUS_DATA_INBUS[5]} {BUS_DATA_INBUS[6]} {BUS_DATA_INBUS[7]} {BUS_DATA_INBUS[8]} {BUS_DATA_INBUS[9]} {BUS_DATA_INBUS[10]} {BUS_DATA_INBUS[11]} {BUS_DATA_INBUS[12]} {BUS_DATA_INBUS[13]} {BUS_DATA_INBUS[14]} {BUS_DATA_INBUS[15]} {BUS_DATA_INBUS[16]} {BUS_DATA_INBUS[17]} {BUS_DATA_INBUS[18]} {BUS_DATA_INBUS[19]} {BUS_DATA_INBUS[20]} {BUS_DATA_INBUS[21]} {BUS_DATA_INBUS[22]} {BUS_DATA_INBUS[23]} {BUS_DATA_INBUS[24]} {BUS_DATA_INBUS[25]} {BUS_DATA_INBUS[26]} {BUS_DATA_INBUS[27]} {BUS_DATA_INBUS[28]} {BUS_DATA_INBUS[29]} {BUS_DATA_INBUS[30]} {BUS_DATA_INBUS[31]}}

editPin -fixedPin 1 -snap TRACK -side Right -unit TRACK -layer 2 -spreadType center -spacing 10.0 \
    -pin { BUS_BUSY BUS_MW BUS_MR {BUS_ADDR_OUTBUS[0]} {BUS_ADDR_OUTBUS[1]} {BUS_ADDR_OUTBUS[2]} {BUS_ADDR_OUTBUS[3]} {BUS_ADDR_OUTBUS[4]} {BUS_ADDR_OUTBUS[5]} {BUS_ADDR_OUTBUS[6]} {BUS_ADDR_OUTBUS[7]} {BUS_ADDR_OUTBUS[8]} {BUS_ADDR_OUTBUS[9]} {BUS_ADDR_OUTBUS[10]} {BUS_ADDR_OUTBUS[11]} {BUS_ADDR_OUTBUS[12]} {BUS_ADDR_OUTBUS[13]} {BUS_ADDR_OUTBUS[14]} {BUS_ADDR_OUTBUS[15]} {BUS_ADDR_OUTBUS[16]} {BUS_ADDR_OUTBUS[17]} {BUS_ADDR_OUTBUS[18]} {BUS_ADDR_OUTBUS[19]} {BUS_ADDR_OUTBUS[20]} {BUS_ADDR_OUTBUS[21]} {BUS_ADDR_OUTBUS[22]} {BUS_ADDR_OUTBUS[23]} {BUS_ADDR_OUTBUS[24]} {BUS_ADDR_OUTBUS[25]} {BUS_ADDR_OUTBUS[26]} {BUS_ADDR_OUTBUS[27]} {BUS_ADDR_OUTBUS[28]} {BUS_ADDR_OUTBUS[29]} {BUS_ADDR_OUTBUS[30]} {BUS_ADDR_OUTBUS[31]}}

editPin -fixedPin 1 -snap TRACK -side Left -unit TRACK -layer 2 -spreadType center -spacing 10.0 \
	-pin {{BUS_DATA_OUTBUS[0]} {BUS_DATA_OUTBUS[1]} {BUS_DATA_OUTBUS[2]} {BUS_DATA_OUTBUS[3]} {BUS_DATA_OUTBUS[4]} {BUS_DATA_OUTBUS[5]} {BUS_DATA_OUTBUS[6]} {BUS_DATA_OUTBUS[7]} {BUS_DATA_OUTBUS[8]} {BUS_DATA_OUTBUS[9]} {BUS_DATA_OUTBUS[10]} {BUS_DATA_OUTBUS[11]} {BUS_DATA_OUTBUS[12]} {BUS_DATA_OUTBUS[13]} {BUS_DATA_OUTBUS[14]} {BUS_DATA_OUTBUS[15]}  {BUS_DATA_OUTBUS[16]} {BUS_DATA_OUTBUS[17]} {BUS_DATA_OUTBUS[18]} {BUS_DATA_OUTBUS[19]} {BUS_DATA_OUTBUS[20]} {BUS_DATA_OUTBUS[21]} {BUS_DATA_OUTBUS[22]} {BUS_DATA_OUTBUS[23]} {BUS_DATA_OUTBUS[24]} {BUS_DATA_OUTBUS[25]} {BUS_DATA_OUTBUS[26]} {BUS_DATA_OUTBUS[27]} {BUS_DATA_OUTBUS[28]} {BUS_DATA_OUTBUS[29]} {BUS_DATA_OUTBUS[30]} {BUS_DATA_OUTBUS[31]}}

# Building a Power Ring for Vdd / Vdds, extending top/bottom segments to create pins
# From the LEF file we know that M9 and M10 are the highest metals, and that the min width of the M9 M10 metals
# is 0.8. We need to make this ring a multiple of 0.8.Since the area is small, we dont expect huge consumption,
# we keep it at pitch. 
# Note that in the foorplan we must reserve enough space between core (rows) and pins to build rings 

placeInstance IMem 30  20 R0 -fixed
placeInstance DMem 204 20 R0 -fixed

addHaloToBlock 10 10 10 10 -allBlock

addRing -width_left 0.8 -width_bottom 0.8 -width_top 0.8 -width_right 0.8 \
        -spacing_bottom 0.8 -spacing_top 0.8 -spacing_left 0.8 -spacing_right 0.8 \
        -layer_top metal9 -layer_bottom metal9 -layer_left metal10 -layer_right metal10 \
        -lb 1 -lt 1 -rb 1 -rt 1 -nets {VDD VSS}

# Note:for such a small design it is not necessary to build a whole 
addStripe -direction vertical \
          -set_to_set_distance 9.6     \
          -spacing 4 \
          -layer metal10 -width 0.8 -nets {VSS VDD } 
          
sroute -noPadPins -noPadRings -routingEffort allowShortJogs  -nets {VDD VSS}

defOut -floorplan -noStdCells results/up_island_floor.def




saveDesign ./DBS/02-floorplan.enc -relativePath -compress

# Create LEF
lefOut results/$TOP.lef

# Generate Timing Model (need for embedded module)
do_extract_model results/$TOP.lib

summaryReport -outfile results/summary/02-floorplan.rpt

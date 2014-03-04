#######################################################
#                                                     #
#  Encounter Command Logging File                     #
#  Created on Mon Feb 24 11:40:02 2014                #
#                                                     #
#######################################################

#@(#)CDS: Encounter v09.10-p004_1 (32bit) 12/02/2009 20:50 (Linux 2.6)
#@(#)CDS: NanoRoute v09.10-p020 NR091118-1115/USR62-UB (database version 2.30, 86.1.1) {superthreading v1.13}
#@(#)CDS: CeltIC v09.10-p001_1 (32bit) 11/20/2009 16:06:17 (Linux 2.6.9-78.0.25.ELsmp)
#@(#)CDS: CTE 09.10-p003_1 (32bit) Dec  2 2009 16:44:23 (Linux 2.6.9-78.ELsmp)
#@(#)CDS: CPE v09.10-p005

set_global report_precision 5
loadConfig inputs/SRAM.conf
setCteReport
saveDesign ./DBS/01-importDesign.enc -relativePath -compress
setAnalysisMode -analysistype single -checkType setup -skew true -clockPropagation sdcControl
timeDesign -drvReports -slackReports -pathreports -expandReg2Reg -expandedViews -reportOnly -numPaths 10 -outDir results/timing/01-importDesign-timeDesign.setup
report_timing -net -format {instance arc cell slew net annotation load delay arrival} -max_paths 10 >  results/timing/01_Timing.rpt
summaryReport -outfile results/summary/01-importDesign.rpt
fit
getIoFlowFlag
floorPlan -su 1 0.94 4 4 4 4
editPin -fixedPin 1 -snap TRACK -side Top -unit TRACK -layer 2 -spreadType center -spacing 5.0 -pin {clk rdn wrn {address[0]} {address[1]} {address[2]} {address[3]} {address[4]} {address[5]} {address[6]} {address[7]} {address[8]} {address[9]} {address[10]} {address[11]} {address[12]} {address[13]} {data_in[0]} {data_in[1]} {data_in[2]} {data_in[3]} {data_in[4]} {data_in[5]} {data_in[6]} {data_in[7]} {data_in[8]} {data_in[9]} {data_in[10]} {data_in[11]} {data_in[12]} {data_in[13]} {data_in[14]} {data_in[15]} {data_in[16]} {data_in[17]} {data_in[18]} {data_in[19]} {data_in[20]} {data_in[21]} {data_in[22]} {data_in[23]} {data_in[24]} {data_in[25]} {data_in[26]} {data_in[27]} {data_in[28]} {data_in[29]} {data_in[30]} {data_in[31]}}
editPin -fixedPin 1 -snap TRACK -side Bottom -unit TRACK -layer 2 -spreadType center -spacing 10.0 -pin {{data_out[0]} {data_out[1]} {data_out[2]} {data_out[3]} {data_out[4]} {data_out[5]} {data_out[6]} {data_out[7]} {data_out[8]} {data_out[9]} {data_out[10]} {data_out[11]} {data_out[12]} {data_out[13]} {data_out[14]} {data_out[15]} {data_out[16]} {data_out[17]} {data_out[18]} {data_out[19]} {data_out[20]} {data_out[21]} {data_out[22]} {data_out[23]} {data_out[24]} {data_out[25]} {data_out[26]} {data_out[27]} {data_out[28]} {data_out[29]} {data_out[30]} {data_out[31]}}
addRing -width_left 0.8 -width_bottom 0.8 -width_top 0.8 -width_right 0.8 -spacing_bottom 0.8 -spacing_top 0.8 -spacing_left 0.8 -spacing_right 0.8 -layer_top metal9 -layer_bottom metal9 -layer_left metal10 -layer_right metal10 -lb 1 -lt 1 -rb 1 -rt 1 -nets {VDD VSS}
addStripe -direction vertical -set_to_set_distance 9.6 -spacing 4 -layer metal10 -width 0.8 -nets {VSS VDD }
sroute -noPadPins -noPadRings -routingEffort allowShortJogs -nets {VDD VSS}
defOut -floorplan -noStdCells results/SRAM_floor.def
saveDesign ./DBS/02-floorplan.enc -relativePath -compress
lefOut results/SRAM.lef
do_extract_model results/$TOP.lib
summaryReport -outfile results/summary/02-floorplan.rpt
fit

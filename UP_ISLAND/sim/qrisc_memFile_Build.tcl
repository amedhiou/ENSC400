#!/usr/bin/tclsh

# qrisc_memfile_Build.tcl 
# fcampi@sfu.ca jan 2014

# Simple utility for converting GCC mraw files into Modelsim readable files


# Checking argument files: this file has only one argument, and that is the file to be read!
if { $argc != 3 } {
    puts "Format: memfile_Build.tcl <GCC mraw file> <Modelsim IMem File Name> <Modelsim DMem File Name>";
    exit
}
 
# Reading input file. If Input files get too long, this will have to be revised as it loads the whole
# file into memory before processing it
set fp [open [lindex $argv 0] r]
set file_data [read $fp]
close $fp

set imemfile [open [lindex $argv 1] w+ ]
set dmemfile [open [lindex $argv 2] w+ ]

puts $imemfile "// memory instruction file"
puts $imemfile "// format=mti addressradix=h dataradix=h version=1.0 wordsperline=4"

puts $dmemfile "// memory instruction file"
puts $dmemfile "// format=mti addressradix=h dataradix=h version=1.0 wordsperline=4"

#  Process data file
set curfile "NULL"
set data [split $file_data "\n"]
foreach line $data {
    if {[regexp {Contents of section (.*):} $line -> secName]} {
	puts "Entering Section $secName"; 
	if {![string compare $secName ".text"]} {
	    set curfile $imemfile;
	} elseif {(![string compare $secName ".sdata"]) | (![string compare $secName ".data"]) | (![string compare $secName ".rodata"]) } {
	    set curfile $dmemfile;
	} else {
	    set curfile "NULL";
	}
    } 

    if {![string compare $curfile $imemfile]} {
	if {[regexp {([0-9a-f]{8})\s(.*)} $line -> addr words]} {
	    set word [regexp -inline -all {[0-9a-f]{8}} $words];	
	    puts $curfile "[format %4.4X [expr (0x$addr-0x40000000)/4]]: $word";
	}
    } elseif {![string compare $curfile $dmemfile]} {
	if {[regexp {([0-9a-f]{8})\s(.*)} $line -> addr words]} {
	    set word [regexp -inline -all {[0-9a-f]{8}} $words];	
	    puts $curfile "[format %4.4X [expr (0x$addr-0x40010000)/4]]: $word";
	}
    }
}

close $imemfile

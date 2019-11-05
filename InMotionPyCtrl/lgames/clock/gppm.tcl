#! /usr/bin/tclsh

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# plot performance metrics

proc gppm {fn {print screen}} {

    set tail [file tail $fn]
    set dname [file dirname $fn]


    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]
    # set gp stdout

    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set key off"
    puts $gp "set yrange \[0:100]"
    puts $gp "set xrange \[0:6]"
    puts $gp "set grid"
    puts $gp "set xtics ('initiated movement' 1, \
		'maximum dist along axis' 2, \
		'active power' 3, \
		'minimum jerk deviation' 4, \
		'dist from straight line' 5)"

    # magnitude labels at base of bars
    # read fn file into pmlist
    # data is in every other column
    # data has lots of noise after decimal point, round it.
    set pmlist [exec cat $fn]
    foreach i {1 3 5 7 9} {
	set var [expr {round([lindex $pmlist $i])}]
	set xloc [expr {($i-1)/2 + .65}]
	puts $gp "set label '$var' at $xloc,3"
    }

    # lw 50 gives us fat impulse bars
    puts -nonewline $gp "plot"
    puts -nonewline $gp  " \"$fn\" u 1:2 w imp lw 50"
    puts -nonewline $gp ", '' u 3:4 w imp lw 50"
    puts -nonewline $gp ", '' u 5:6 w imp lw 50"
    puts -nonewline $gp ", '' u 7:8 w imp lw 50"
    puts            $gp ", '' u 9:10 w imp lw 50"


    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gppm [lindex $argv 0] [lindex $argv 1]

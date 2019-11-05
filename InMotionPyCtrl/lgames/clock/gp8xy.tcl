#! /usr/bin/tclsh

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# plot 8 directional x/y pos plots

# the other scripts have color choosing stuff.
# since these are all x/y, just use default red.

proc gp8 {fn {print screen}} {
    # puts "gp8 $fn"
    set dname [file dirname $fn]
    set tail [file tail $fn]

    set pat {^(\w+)_(\d{6})_([SN]*[WE]?)([bt])(\d+).dat$}

    regexp $pat $tail full game time dir bt num

    # puts "full: $full"
    # puts "dname: $dname game: $game time: $time dir: $dir bt: $bt num: $num"

    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]

    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set multiplot"
    puts $gp "set size square"
    puts $gp "set size 0.33,0.33"
    puts $gp "set xtics .1"
    puts $gp "set ytics .1"
    puts $gp "set xrange \[-.2:.2\]"
    puts $gp "set yrange \[-.2:.2\]"
    puts $gp "set key off"
    puts $gp "set grid"

    puts $gp "set label \"$dname\"     at screen .33,.6"
    puts $gp "set label \"$tail\"     at screen .33,.575"
    puts $gp "set label 'plots of y position (m) vs x position (m)' at screen .33,.55"

    set n 0

    # 8 directions
    set dlist {
    1 N .33 .66
    2 NE .66 .66
    3 E .66 .33
    4 SE .66 0.0
    5 S .33 0.0
    6 SW 0.0 0.0
    7 W 0.0 .33
    8 NW 0.0 .66
    }

    # we always want the right graph in the right place.
    # turn any number from 1-8 into 0, 9-16 into 8.
    set num [expr {($num - 1) & ~7}]

    # plot 3x3, with lower left at 0.0, upper right at .66x.66

    foreach {i d x y}  $dlist {
	set n [expr {$num + $i}]
	set pfile "${dname}/${game}_${time}_$d$bt$n.dat"
	if [file exists $pfile] {
	    puts $gp "set origin $x,$y"
	    puts $gp "plot \"< $::env(CROB_HOME)/ta.tcl $pfile\" u 2:3 w l lw 3"
	}
    }
    puts $gp "set nomultiplot"
    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gp8 [lindex $argv 0] [lindex $argv 1]

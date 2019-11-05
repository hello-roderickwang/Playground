#! /usr/bin/tclsh

# single xy plot of multi files

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# plot 16 directional x/y pos plots

# the other scripts have color choosing stuff.
# since these are all x/y, just use default red.

source $env(LGAMES_HOME)/common/util.tcl

proc gp1xy {fn {print screen}} {
    global env
    set current_robot [current_robot]
    # make planarhand look like planar, for now...
    if {$current_robot == "planarhand"} {set current_robot "planar"}
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

    puts $gp "set key rmargin horizontal maxcols 1"
    puts $gp "set title \"${dname}/${game}_${time}\""
    if {$current_robot == "wrist"} {
	puts $gp "set xlabel \"flex/ext angle (rad)\""
	puts $gp "set ylabel \"ab/ad angle (rad)\""
	puts $gp "set xrange \[-1.:1.\]"
	puts $gp "set yrange \[-.5:.5\]"
    } elseif {$current_robot == "planar"} {
	puts $gp "set xlabel \"x position (m)\""
	puts $gp "set ylabel \"y position (m)\""
	puts $gp "set xrange \[-.2:.2\]"
	puts $gp "set yrange \[-.2:.2\]"
    } else {
	error "plot: robot type $current_robot not yet supported."
    }
    puts $gp "set size square"
    puts $gp "set grid"

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

    puts -nonewline $gp "plot "
    foreach {i d x y}  $dlist {
        set n [expr {$num + $i}]
        set pfile "${dname}/${game}_${time}_${d}t$n.dat"
        if [file exists $pfile] {
            if {$i != 1} {puts -nonewline $gp ","}
	    puts -nonewline $gp "\"< $env(CROB_HOME)/ta.tcl $pfile\" u 2:3 title \"${d}t$n\" w l lw 3"
	}
        set pfile "${dname}/${game}_${time}_${d}b$n.dat"
        if [file exists $pfile] {
	    puts -nonewline $gp ",\"< $env(CROB_HOME)/ta.tcl $pfile\" u 2:3 title \"${d}b$n\" w l lw 3"
	}
    }

    puts $gp ""

    puts $gp "set nomultiplot"
    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gp1xy [lindex $argv 0] [lindex $argv 1]

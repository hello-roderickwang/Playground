#! /usr/bin/tclsh

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# gs -sDEVICE=gdi -sOutputFile=/tmp/out.gdi - < /tmp/out.ps

proc gp8 {fn {print screen}} {
    # puts "gp8 $fn"

    set dname [file dirname $fn]
    set tail [file tail $fn]
    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]

    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set multiplot"
    puts $gp "set size square"
    puts $gp "set size 0.35,0.35"
    puts $gp "set key off"
    puts $gp "set grid"

    puts $gp "set label \"$dname\" at screen .05,.90" 
    puts $gp "set label \"$tail\" at screen .05,.875"
    puts $gp "set label \"phase plots\" at screen .05,.85"

    puts $gp "set label \"y pos (m) vs x pos (m)\" at screen .05,.75"
    puts $gp "set label \"y vel (m/s) vs x vel (m/s)\" at screen .55,.75"
    puts $gp "set label \"y force (N) vs x force (N)\" at screen .05,.35"



    set n 0

    # 8 directions
    set dlist {
    1 x y 2 3 0.0 0.4
    2 vx vy 4 5 0.5 0.4
    3 fx fy 6 7 0.0 0.0
    }

    # plot 3x3, with lower left at 0.0, upper right at .66x.66

    foreach {i dx dy nx ny ox oy}  $dlist {


	switch $dx {
	x -
	y {
	     puts $gp "set xrange \[-.2:.2\]"
	     puts $gp "set xtics .1"
	}
	vx -
	vy {
	     puts $gp "set xrange \[-1.0:1.0\]"
	     puts $gp "set xtics .5"
	}
	fx -
	fy {
	     puts $gp "set xrange \[-40.0:40.0\]"
	     puts $gp "set xtics 20"
	}
	fz {
	     puts $gp "set xrange \[-80.0:80.0\]"
	     puts $gp "set xtics 40"
	}
	}

	# set color based on y axis data.

	set linecolor "lt 1"

	switch $dy {
	x -
	y {
	     puts $gp "set yrange \[-.2:.2\]"
	     puts $gp "set ytics .1"
	}
	vx -
	vy {
	     puts $gp "set yrange \[-1.0:1.0\]"
	     puts $gp "set ytics .5"
	     set linecolor "lt 3"
	}
	fx -
	fy {
	     puts $gp "set yrange \[-40.0:40.0\]"
	     puts $gp "set ytics 20"
	     set linecolor "lt 4"
	}
	fz {
	     puts $gp "set yrange \[-80.0:80.0\]"
	     puts $gp "set ytics 40"
	     set linecolor "lt 4"
	}
	}

	# colors on x11 become dotted lines on ps, don't do that.
	if [string match $print "print"] {
	    set linecolor ""
	}

	puts $gp "set origin $ox,$oy"
	puts $gp "plot \"< $::env(CROB_HOME)/ta.tcl $fn\" u $nx:$ny w l $linecolor lw 3"
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

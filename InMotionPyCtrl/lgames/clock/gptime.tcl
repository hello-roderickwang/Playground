#! /usr/bin/tclsh

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# gs -sDEVICE=gdi -sOutputFile=/tmp/out.gdi - < /tmp/out.ps

source $env(LGAMES_HOME)/common/util.tcl

proc gptime {fn {print screen}} {
    global env
    # puts "gptime $fn"

    set current_robot [current_robot]
    if {$current_robot == "planarhand"} {set current_robot "planar"}
    set dname [file dirname $fn]
    set tail [file tail $fn]

    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]

    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set multiplot"
    puts $gp "set size square"
    puts $gp "set size 0.3,0.3"
    puts $gp "set key off"
    puts $gp "set grid"

    set n 0

if {$current_robot == "planar"} {
    # 8 directions
    set dlist {
    2 x 0.0 0.5
    3 y 0.25 0.5
    4 vx 0.5 0.5
    5 vy 0.75 0.5

    6 fx 0.0 0.0
    7 fy 0.25 0.0
    8 fz 0.5 0.0
    }
    # 9 g 0.75 0.5
} elseif {$current_robot == "wrist"} {
    set dlist {
    2 fe 0.0 0.5
    3 aa 0.25 0.5

    5 vfe 0.5 0.5
    6 vaa 0.75 0.5

    8 tfe 0.0 0.0
    9 taa 0.25 0.0
    10 tps 0.5 0.0
    }
}

    # plot 3x3, with lower left at 0.0, upper right at .66x.66

    puts $gp "set label \"$dname\"     at screen .05,.90"
    puts $gp "set label \"$tail\"     at screen .05,.875"
    puts $gp "set label \"plots vs time\"     at screen .05,.85"

if {$current_robot == "planar"} {
    puts $gp "set label 'x position (m) vs time (s)' at screen .05,.80"
    puts $gp "set label 'y position (m) vs time (s)' at screen .30,.80"
    puts $gp "set label 'x velocity (m/s) vs time (s)' at screen .55,.80"
    puts $gp "set label 'y velocity (m/s) vs time (s)' at screen .80,.80"

    puts $gp "set label 'x force (N) vs time (s)' at screen .05,.30"
    puts $gp "set label 'y force (N) vs time (s)' at screen .30,.30"
    puts $gp "set label 'z force (N) vs time (s)' at screen .55,.30"
    puts $gp "set label 'y pos (m) vs x pos (m)'  at screen .80,.30"
} elseif {$current_robot == "wrist"} {
    puts $gp "set label 'fe position (rad) vs time (s)' at screen .05,.80"
    puts $gp "set label 'aa position (rad) vs time (s)' at screen .30,.80"
    puts $gp "set label 'fe velocity (rad/s) vs time (s)' at screen .55,.80"
    puts $gp "set label 'aa velocity (rad/s) vs time (s)' at screen .80,.80"

    puts $gp "set label 'fe torque (Nm) vs time (s)' at screen .05,.30"
    puts $gp "set label 'aa torque (Nm) vs time (s)' at screen .30,.30"
    puts $gp "set label 'ps torque (Nm) vs time (s)' at screen .55,.30"
    puts $gp "set label 'aa pos (rad) vs fe pos (rad)'  at screen .80,.30"
}

    puts $gp "set xtics 1"

    set linecolor " lt 1"

    foreach {i d x y}  $dlist {
if {$current_robot == "planar"} {
    switch $d {
    x -
    y {
	puts $gp "set yrange \[-.2:.2\]"
	puts $gp "set ytics .1"
	puts $gp "set ytics .1"
    }
    vx -
    vy {
         puts $gp "set yrange \[-1.0:1.0\]"
         puts $gp "set ytics .5"
	set linecolor " lt 3"
    }
    fx -
    fy {
         puts $gp "set yrange \[-40.0:40.0\]"
         puts $gp "set ytics 20"
	set linecolor " lt 4"
    }
    fz {
         puts $gp "set yrange \[-80.0:80.0\]"
         puts $gp "set ytics 40"
	set linecolor " lt 4"
    }
    }
} elseif {$current_robot == "wrist"} {
    switch $d {
    fe {
	puts $gp "set yrange \[-1.:1.\]"
    }
    aa {
	puts $gp "set yrange \[-.5:.5\]"
    }
    vfe {
	puts $gp "set yrange \[-4.0:4.0\]"
	set linecolor " lt 3"
    }
    vaa {
	puts $gp "set yrange \[-2.0:2.0\]"
	set linecolor " lt 3"
    }
    tfe {
	puts $gp "set yrange \[-10.0:10.0\]"
	set linecolor " lt 4"
    }
    taa {
	puts $gp "set yrange \[-5.0:5.0\]"
	set linecolor " lt 4"
    }
    tps {
	puts $gp "set yrange \[-20.0:20.0\]"
	set linecolor " lt 4"
    }
    }
}

    # colors on x11 become dotted lines on ps, don't do that.
    if [string match $print "print"] {
	set linecolor ""
    }

	puts $gp "set origin $x,$y"
	puts $gp "plot \"< $::env(CROB_HOME)/ta.tcl $fn\" u (\$0/200.0):$i w l $linecolor lw 3"
    }

    puts $gp "set origin 0.75,0.0"
    puts $gp "set xrange \[-1.:1.\]"
    puts $gp "set yrange \[-.5:.5\]"

    puts $gp "plot \"< $::env(CROB_HOME)/ta.tcl $fn\" u 2:3 w l lw 3"

    puts $gp "set nomultiplot"
    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gptime [lindex $argv 0] [lindex $argv 1]

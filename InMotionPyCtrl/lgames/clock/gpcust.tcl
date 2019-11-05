#! /usr/bin/tclsh

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

source $env(LGAMES_HOME)/common/util.tcl

proc gpcust {fn {x x} {y y} {print screen}} {

    set current_robot [current_robot]
    # make planarhand look like planar, for now...
    if {$current_robot == "planarhand"} {set current_robot "planar"}

    # puts "gpcust $fn $x $y"
    set dname [file dirname $fn]
    set tail [file tail $fn]

    switch $current_robot {
    planar {
    array set col {time 1 x 2 y 3 vx 4 vy 5 fx 6 fy 7 fz 8 grasp 9}
    array set lab {time "time (s)" x "position x (m)" y "position y (m)"
	vx "velocity x (m/s)" vy "velocity y (m/s)"
	fx "force x (N)"
	fy "force y (N)"
	fz "force z (N)"
	grasp "grasp"
    }
    }

    wrist {
    array set col {time 1 fe 2 aa 3 ps 4 vfe 5 vaa 6 vps 7 tfe 8 taa 9 tps 10}
    array set lab {time "time (s)"
    fe "position fe (rad)"
    aa "position aa (rad)"
    ps "position ps (rad)"
    vfe "velocity fe (rad/s)"
    vaa "velocity aa (rad/s)"
    vps "velocity ps (rad/s)"
    tfe "torque fe (Nm)"
    taa "torque aa (Nm)"
    tps "torque ps (Nm)"
    }
    }

    linear {
    array set col {time 1 pos 2 vel 3 frc 4}
    array set lab {time "time (s)" pos "position (m)"
	vel "velocity (m/s)" frc "force (N)"
    }
    }

    }
    set colx $col($x)
    set coly $col($y)
    set labx $lab($x)
    set laby $lab($y)

    set tail [file tail $fn]
    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]


    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set key off"

    puts $gp "set label \"$dname\" at screen .15,.90" 
    puts $gp "set label \"$tail\" at screen .15,.875"
    puts $gp "set xlabel \"$labx\""
    puts $gp "set ylabel \"$laby\""
    puts $gp "set grid"

    switch $current_robot {
    planar {
    switch $x {
    time {
	 set colx (\$0/200.0)
    }
    x -
    y {
	 puts $gp "set xrange \[-.2:.2\]"
	 puts $gp "set xtics .05"

    }
    vx -
    vy {
	 puts $gp "set xrange \[-1.0:1.0\]"
	 puts $gp "set xtics .25"
    }
    fx -
    fy {
	 puts $gp "set xrange \[-40.0:40.0\]"
	 puts $gp "set xtics 10"
    }
    fz {
	 puts $gp "set xrange \[-80.0:80.0\]"
	 puts $gp "set xtics 20"
    }
    }

    set linecolor "lt 1"

    # set colors based on y axis data.
    switch $y {
    time {
	 set coly (\$0/200.0)
    }
    x -
    y {
	 puts $gp "set yrange \[-.2:.2\]"
	 puts $gp "set ytics .05"
    }
    vx -
    vy {
	 puts $gp "set yrange \[-1.0:1.0\]"
	 puts $gp "set ytics .25"
	 set linecolor "lt 3"
    }
    fx -
    fy {
	 puts $gp "set yrange \[-40.0:40.0\]"
	 puts $gp "set ytics 10"
	 set linecolor "lt 4"
    }
    fz {
	 puts $gp "set yrange \[-80.0:80.0\]"
	 puts $gp "set ytics 20"
	 set linecolor "lt 4"
    }
    }

    # x/y vx/vy fx/fy
    if {($colx == 2 && $coly == 3)
    	|| ($colx == 3 && $coly == 2)
    	|| ($colx == 4 && $coly == 5)
    	|| ($colx == 5 && $coly == 4)
    	|| ($colx == 6 && $coly == 7)
    	|| ($colx == 7 && $coly == 6)} {
	puts $gp "set size square"
    }
    }

    wrist {
    switch $x {
    time {
	 set colx (\$0/200.0)
    }
    fe {
	 puts $gp "set xrange \[-1.:1.\]"
    }
    aa {
	 puts $gp "set xrange \[-.5:.5\]"
    }
    ps {
	 puts $gp "set xrange \[-.8:.8\]"
	 puts $gp "set xtics .2"

    }
    vfe {
	 puts $gp "set xrange \[-4.:4.\]"
	}
    vaa {
	 puts $gp "set xrange \[-2.:2.\]"
    }
    vps {
	 puts $gp "set xrange \[-4.0:4.0\]"
	 puts $gp "set xtics 1."
    }
    tfe {
	 puts $gp "set xrange \[-10.:10.\]"
	}
    taa {
	 puts $gp "set xrange \[-5.:5.\]"
    }
    tps {
	 puts $gp "set xrange \[-20.0:20.0\]"
	 puts $gp "set xtics 10"
    }
    }

    set linecolor "lt 1"

    # set colors based on y axis data.
    switch $y {
    time {
	 set coly (\$0/200.0)
    }
    fe {
	 puts $gp "set yrange \[-1.:1.\]"
    }
    aa {
	 puts $gp "set yrange \[-.5:.5\]"
    }
    ps {
	 puts $gp "set yrange \[-.8:.8\]"
	 puts $gp "set ytics .2"
    }
    vfe {
	 puts $gp "set yrange \[-2.:2.\]"
    }
    vaa {
	 puts $gp "set yrange \[-1.:1.\]"
    }
    vps {
	 puts $gp "set yrange \[-4.0:4.0\]"
	 puts $gp "set ytics 1.0"
	 set linecolor "lt 3"
    }
    tfe {
	 puts $gp "set yrange \[-10.:10.\]"
	}
    taa {
	 puts $gp "set yrange \[-5.:5.\]"
    }
    tps {
	 puts $gp "set yrange \[-20.0:20.0\]"
	 puts $gp "set ytics 10"
	 set linecolor "lt 4"
    }
    fz {
	 puts $gp "set yrange \[-80.0:80.0\]"
	 puts $gp "set ytics 20"
	 set linecolor "lt 4"
    }
    }

    # fe/aa vfe/vaa, etc.
    if {($colx == 2 && $coly == 3)
    	|| ($colx == 3 && $coly == 2)
    	|| ($colx == 5 && $coly == 6)
    	|| ($colx == 6 && $coly == 5)
    	|| ($colx == 8 && $coly == 9)
    	|| ($colx == 9 && $coly == 8)} {
	puts $gp "set size square"
    }
    }

    linear {
    switch $x {
    time {
	 set colx (\$0/200.0)
    }
    pos {
	 puts $gp "set xrange \[-.2:.2\]"
	 puts $gp "set xtics .05"

    }
    vel {
	 puts $gp "set xrange \[-1.0:1.0\]"
	 puts $gp "set xtics .25"
    }
    frc {
	 puts $gp "set xrange \[-40.0:40.0\]"
	 puts $gp "set xtics 10"
    }
    }

    set linecolor "lt 1"

    # set colors based on y axis data.
    switch $y {
    time {
	 set coly (\$0/200.0)
    }
    pos {
	 puts $gp "set yrange \[-.2:.2\]"
	 puts $gp "set ytics .05"

    }
    vel {
	 puts $gp "set yrange \[-1.0:1.0\]"
	 puts $gp "set ytics .25"
    }
    frc {
	 puts $gp "set yrange \[-40.0:40.0\]"
	 puts $gp "set ytics 10"
    }
    }

    # no square plots, because no pos v pos, etc.

    }
    }

    # colors on x11 become dotted lines on ps, don't do that.
    if [string match $print "print"] {
        set linecolor ""
    }

    puts $gp "plot \"< $::env(CROB_HOME)/ta.tcl $fn\" u $colx:$coly w l $linecolor lw 3"

    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gpcust [lindex $argv 0] [lindex $argv 1] [lindex $argv 2] [lindex $argv 3]

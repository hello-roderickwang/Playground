#!  /usr/bin/wish

# this is a sample program that shows two object balls on a canvas.
# the small yellow ball is a cursor, it follows the robot.

# note, the idiom:
# foreach {a b c d} {1 2 3 4} break
# sets a to 1, b to 2, c to 3, and d to 4.

package require Tk

source ../shm.tcl

bind . <Key-q> done
bind . <Key-g> domove

start_rtl

# given a center position and radius, like 100 100 10,
# ballxy returns x1 y1 x2 y2, like 90 90 110 110.

proc ballxy {x y rad} {
        set x1 [expr {$x - $rad}]
        set y1 [expr {$y - $rad}]
        set x2 [expr {$x + $rad}]
        set y2 [expr {$y + $rad}]
	list $x1 $y1 $x2 $y2
}

# do body every ms milliseconds

proc every {ms body} {eval $body; after $ms [info level 0]}

# returns a random int between min and max-1

proc irand {min max} {
	expr {int(rand() * ($max-$min)) + $min}
}

# returns the x and y cursor position with 0,0 at the upper-left
# edge of the canvas window
# winfo pointer returns full-screen cursor position.
# winfo root returns window 0,0 position.

proc getcurxy {w} {
	# set x [rshm wrist_fe_pos]
	# set y [rshm wrist_aa_pos]
	set x [rshm x]
	set y [rshm y]
	set x [expr {$x * 1000.}]
	set y [expr {$y * -1000.}]
	list $x $y
}	

proc done {} {
	stop_log
	stop_rtl
	exit
}

# make a canvas, pack it, and create a cursor

canvas .c -width 600 -height 600
pack .c

set cursor [.c create oval [ballxy 100 100 10] -fill yellow]

.c config -scrollregion [list -300 -300 300 300]

set pi [expr {atan(1) * 4.}]
set term 1000
set amplitude 100

set coords {}
for {set i 0} {$i < $term} {incr i} {
	set x [expr { ($amplitude * cos((2.0 * $pi * $i / $term) + 0))}]
	set y [expr { ($amplitude * cos((2.0 * $pi * $i / $term) + $pi/2.))}]
	lappend coords $x $y
}

.c create line $coords -width 3

proc domove {} {
	.c delete spot
	wshm logfnid 0

	# for wrist
	# wshm logfnid 8
	# start_log /tmp/circle.dat 11
	# set ctl 10

	# for planar
	wshm logfnid 0
	start_log /tmp/circle.dat 8
	set ctl 13

	movebox 0 $ctl {0 1000 1} {0.0 0.0 0.0 0.0} {0.0 0.0 0.0 0.0}
	after 5000 stop_log
}

# called 20x per second.
every 50 {
	# get mouse cursor position
	foreach {x y} [getcurxy .c] break

	# move yellow cursor ball to match it.
	.c create oval [ballxy $x $y 10] -tag spot -fill red
        .c coords $::cursor [ballxy $x $y 10]
	.c raise $::cursor

}

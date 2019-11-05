#!  /usr/bin/wish

# this is a sample program that shows two object balls on a canvas.
# the small yellow ball is a cursor, it follows the mouse.
# the large red ball is the target.
# when the cursor ball touches the target ball,
# the target ball is repositioned at random.


# note, the idiom:
# foreach {a b c d} {1 2 3 4} break
# sets a to 1, b to 2, c to 3, and d to 4.

package require Tk

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
	set x [expr {[winfo pointerx $w] - [winfo rootx $w]}]
	set y [expr {[winfo pointery $w] - [winfo rooty $w]}]
	list $x $y
}	

# reposition the target.
# (called when cursor touches the target.)

proc ballenter {w} {
	set x [irand 100 500]
	set y [irand 100 500]

	set ::target_x $x
	set ::target_y $y
        $w coords $::target [ballxy $x $y 25]
}

# calculate Euclidean distance.
proc edist {x1 y1 x2 y2} {
        expr {hypot($x1 - $x2, $y1 - $y2)}
}


# make a canvas, pack it, and create a cursor and target ball.

canvas .c -width 600 -height 600
pack .c

# set cursor [.c create oval [ballxy 100 100 10] -fill yellow]
set ::target_x 400
set ::target_y 400
set target [.c create oval [ballxy $::target_x $::target_y 25] -fill red]

# center-to-center, radius of target ball + cursor ball
set ::hit_radius 35
set ::i 0

# called 40x per second.
every 25 {
	set ::i [expr {($::i + 1) % 1000}]
	# get mouse cursor position
	foreach {x y} [getcurxy .c] break

	# move yellow cursor ball to match it.
        set ::cursor [.c create oval [ballxy $x $y 10] -fill yellow -tag trail_$::i]
        after 500 .c delete trail_$::i

	set dist [edist $x $y $::target_x $::target_y]
	# if cursor is touching target, call ballenter
        if {$dist < $::hit_radius} {ballenter .c}
}

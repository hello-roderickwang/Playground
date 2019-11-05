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

proc ballenter {ball w} {
	set x [irand 100 500]
	set y [irand 100 500]

        $w coords $::target [ballxy $x $y 25]
}

# make a canvas, pack it, and create a cursor and target ball.

canvas .c -width 600 -height 600
pack .c

set cursor [.c create oval [ballxy 100 100 10] -fill yellow]
set target [.c create oval [ballxy 400 400 25] -fill red]


# called 20x per second.
every 50 {
	# get mouse cursor position
	foreach {x y} [getcurxy .c] break

	# move yellow cursor ball to match it.
        .c coords $::cursor [ballxy $x $y 10]

	# check to see if cursor is touching anything
	set closest [.c find closest $x $y 10 $::cursor]

	# if cursor is touching target, call ballenter
        if {$closest == $::target} { ballenter $closest .c}
}

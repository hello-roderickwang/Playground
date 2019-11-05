#!  /usr/bin/wish

# this is a sample program that shows two object balls on a canvas.
# the small yellow ball is a cursor, it follows the mouse.
# the large red ball is the target.
# when the cursor ball touches the target ball,
# the target ball is repositioned at random.

# this program polls the cursor position 20x/second.
# it is possible to get a similar effect by responding to
# cursor motion events, but this is meant as an example to be used
# when polling a robot "pointer" that doesn't generate mouse events.
# it is possible to have the pointer generate such events with trace,
# or something, but 20x calls per second is ok.

# note, the idiom:
# foreach {a b c d} {1 2 3 4} break
# sets a to 1, b to 2, c to 3, and d to 4.

package require Tk

# given a center position and radius, like 100 100 10,
# centerxy returns x1 y1 x2 y2, like 90 90 110 110.

proc centerxy {x y rad} {
        set x1 [expr {$x - $rad}]
        set y1 [expr {$y - $rad}]
        set x2 [expr {$x + $rad}]
        set y2 [expr {$y + $rad}]
	list $x1 $y1 $x2 $y2
}

# do body every ms milliseconds

proc every {ms body} {eval $body; after $ms [info level 0]}

# returns a random float between min and max
proc frand {min max} {
	expr {rand() * ($max-$min) + $min}
}

# 2000 pixels per meter
set ob(scale) 2000.0

# pass in x or y.  returns cursor position centered and scaled to float.
# side effect, sticks window position in ob(wincur,$p)

proc getptr {p} {
	global ob 
	set w .c
	# cursor position in desktop minus position of tk window
	set val [expr {[.c canvas$p [winfo pointer$p $w]] - [winfo root$p $w]}]
	set ob(wincur,$p) $val
	# flip sign on y coord
	if {$p == "y"} {
		set val [expr {-$val}]
	}
	# scale screen pixels to world meters
	expr {$val / $ob(scale)}
}

# returns the x and y cursor position with 0,0 at the upper-left
# edge of the canvas window
# winfo pointer returns full-screen cursor position.
# winfo root returns window 0,0 position.

proc getcurxy {w} {
	set x [getptr x]
	set y [getptr y]
	list $x $y
}	

# reposition the target.
# (called when cursor touches the target.)

proc ballenter {w} {
	global ob

	set x [expr {[frand -.1 .1]}]
	set y [expr {[frand -.1 .1]}]

	set ob(targetpos,x) $x
	set ob(targetpos,y) $y
        $w coords target [centerxy $x $y .01]
	$w scale target 0 0 $ob(scale) -$ob(scale)
        # puts "ballenter x $x y $y"
}

# calculate Euclidean distance.  (Why not Pythagorean?)
proc edist {x1 y1 x2 y2} {
	expr {hypot($x1 - $x2, $y1 - $y2)}
}

# handle window resize
proc chwin {c w h} {
	global ob
        set ob(half,x) [expr {$w / 2.}]
        set ob(half,y) [expr {$h / 2.}]
        # translate from 0,0 in upper left to 0,0 in center
        $c config -scrollregion [list [expr {-$ob(half,x)}] [expr {-$ob(half,y)}] $ob(half,x) $ob(half,y)]
        puts "$c config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x) $ob(half,y)]"
}


# make a canvas, pack it, and create a cursor and target ball.

canvas .c -width 600 -height 600 -bg gray50
set ob(edgewidth) [expr {([.c cget -highlightthickness] + [.c cget -borderwidth])}]
chwin .c [winfo width .c] [winfo height .c] 
pack .c -fill both -expand true
# handle resize
bind .c <Configure> [list after idle chwin .c %w %h]
bind .c <Configure> [list after idle chwin .c %w %h]
bind . <q> exit

.c create oval [centerxy .1 .1 .005] -fill yellow -tags cursor
.c create oval [centerxy .1 .1 .01] -fill red -tags target
.c scale all 0 0 $ob(scale) -$ob(scale) 
ballenter .c

# called 20x per second.
every 50 {
	global ob
	# get mouse cursor position
	foreach {x y} [getcurxy .c] break
	set wx $ob(wincur,x)
	set wy $ob(wincur,y)

	wm title . "x $x y $y winx $wx winy $wy"
	# move yellow cursor ball to match it.
        .c coords cursor [centerxy $x $y .005]
	.c scale cursor 0 0 $ob(scale) -$ob(scale)

	# it's possible to do this with .c closest, but this is simpler.
	set dist [edist $x $y $ob(targetpos,x) $ob(targetpos,y)]
	# .015 is center to center distance radius .1 + .05
	if {$dist < .015} {
		ballenter .c
	}

}

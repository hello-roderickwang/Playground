#! /usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 9/2000

# a game of 4 wall 4 paddle pong

# you can choose 1-4 live sides.
# live sides return the ball at random
# other sides reflect.

package require Tk

source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

global ob

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

# is this planar or wrist?
localize_robot

# make walls once.
# position and color.
# wall,first and wall,last help with stacking order.

set ob(scale) 2500.0

proc make_walls {} {
	global ob

	set winheight $ob(winheight)
	set winwidth $ob(winwidth)

	# wall width

	set wwid $ob(wwid)

	set ob(ww,n) $wwid
	set ob(ww,s) [expr {$winheight-$wwid}]
	set ob(ww,w) $wwid
	set ob(ww,e) [expr {$winwidth-$wwid}]

	# four walls

	set ob(color,n) yellow
	set x1 0
	set y1 0
	set x2 $winwidth
	set y2 $ob(ww,n)
	set ob(wall,n) [.c create rect $x1 $y1 $x2 $y2 -outline "" \
		-fill $ob(color,n) -tag [list wall wn]]

	set ob(color,s) blue
	set x1 0
	set y1 $ob(ww,s)
	set x2 $winwidth
	set y2 $winheight
	set ob(wall,s) [.c create rect $x1 $y1 $x2 $y2 -outline "" \
		-fill $ob(color,s) -tag [list wall ws]]

	set ob(color,w) red
	set x1 0
	set y1 0
	set x2 $ob(ww,w)
	set y2 $winheight
	set ob(wall,w) [.c create rect $x1 $y1 $x2 $y2 -outline "" \
		-fill $ob(color,w) -tag [list wall ww]]

	set ob(color,e) green1
	set x1 $ob(ww,e)
	set y1 0
	set x2 $winwidth
	set y2 $winheight
	set ob(wall,e) [.c create rect $x1 $y1 $x2 $y2 -outline "" \
		-fill $ob(color,e) -tag [list wall we]]

	set ob(wall,first) $ob(wall,n)
	set ob(wall,last) $ob(wall,e)

	foreach i {n s w e} {
		set ob(livewall,$i) 1
	}
}

# in each game, set up the walls as live (colored) or no (gray)

proc set_walls {} {
	global ob mob

	foreach i {n s w e} {
		if {[string first $i $mob(whichgame)] >= 0} { 
			set ob(livewall,$i) 1
			.c itemconfigure $ob(wall,$i) -fill $ob(color,$i)
		} else {
			set ob(livewall,$i) 0
			.c itemconfigure $ob(wall,$i) -fill gray
		}
	}
}

# make paddles, each new game
# delete them first if they already there
# they will be sized by set_paddles

proc make_paddles {} {
	global ob mob

	if {$mob(round)} {
		set shape oval
	} else {
		set shape rectangle
	}

	foreach i {n s w e} {
		if {[info exists ob(pad,$i)]} {
			.c delete $ob(pad,$i)
		}
		set ob(pad,$i) [.c create $shape 1 1 2 2 -outline "" \
			-fill $ob(color,$i) -tag [list paddle p$i]]
	}
}

# set up the paddles each game.
# dead paddles get stuffed behind dead walls,
# but they're still there.
# (call me lazy)

proc set_paddles {} {
	global ob mob

	set winheight $ob(winheight)
	set wh5 [expr {$winheight - 5}]
	set winwidth $ob(winwidth)
	set ww5 [expr {$winwidth - 5}]
	set cx $ob(half,x)
	set cy $ob(half,y)

        # distance from screen edge to paddle face
        set pdist 133
        set ob(pd,w) $pdist
        set ob(pd,e) [expr {$winwidth-$pdist}]
        set ob(pd,n) $pdist
        set ob(pd,s) [expr {$winheight-$pdist}]

	# paddle dimensions
	regsub -all {[^0-9]} $mob(padw) {} mob(padw)
	set ob(padw) $mob(padw)
	set ob(padw) [bracket $ob(padw) 5 500]

	set ob(padw2) [expr {$ob(padw) / 2}]

	# four paddles
	# make them or stuff them behind the wall,
	# depending on whether they are declared active in mob(whichgame)

	# north
	if {[string first n $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(pd,n)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(pd,n) - $ob(padh)}]
		.c coords $ob(pad,n) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,n) -fill $ob(color,n)
		.c raise $ob(pad,n) $ob(wall,last)
	} else {
		.c coords $ob(pad,n) $cx 5 $cx 5
		.c itemconfigure $ob(pad,n) -fill gray
		.c lower $ob(pad,n) $ob(wall,first)
	}

	# south
	if {[string first s $mob(whichgame)] >= 0} {
		set x1 [expr {$cx - $ob(padw2)}]
		set y1 $ob(pd,s)
		set x2 [expr {$cx + $ob(padw2)}]
		set y2 [expr {$ob(pd,s) + $ob(padh)}]
		.c coords $ob(pad,s) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,s) -fill $ob(color,s)
		.c raise $ob(pad,s) $ob(wall,last)
	} else {
		.c coords $ob(pad,s) $cx $wh5 $cx $wh5
		.c itemconfigure $ob(pad,s) -fill gray
		.c lower $ob(pad,s) $ob(wall,first)
	}

	# west
	if {[string first w $mob(whichgame)] >= 0} {
		set x1 $ob(pd,w)
		set y1 [expr {$cx - $ob(padw2)}]
		set x2 [expr {$ob(pd,w) - $ob(padh)}]
		set y2 [expr {$cx + $ob(padw2)}]
		.c coords $ob(pad,w) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,w) -fill $ob(color,w)
		.c raise $ob(pad,w) $ob(wall,last)
	} else {
		.c coords $ob(pad,w) 5 $cy 5 $cy
		.c itemconfigure $ob(pad,w) -fill gray
		.c lower $ob(pad,w) $ob(wall,first)
	}

	# east
	if {[string first e $mob(whichgame)] >= 0} {
		set x1 $ob(pd,e)
		set y1 [expr {$cx - $ob(padw2)}]
		set x2 [expr {$ob(pd,e) + $ob(padh)}]
		set y2 [expr {$cx + $ob(padw2)}]
		.c coords $ob(pad,e) $x1 $y1 $x2 $y2 
		.c itemconfigure $ob(pad,e) -fill $ob(color,e)
		.c raise $ob(pad,e) $ob(wall,last)
	} else {
		.c coords $ob(pad,e) $ww5 $cy $ww5 $cy
		.c itemconfigure $ob(pad,e) -fill gray
		.c lower $ob(pad,e) $ob(wall,first)
	}

}

# this gets done once.

proc init_pong {} {
	global ob

        # no_arm

	set ob(programname) pong
	set ob(patname) [fnstring $::env(PATID)]
        set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(mainbg) black

	font create default -family Times -size -18
	option add *font default

	game_log_entry begin


	# 1 for sound
	set ob(sound) 0

	if {$ob(sound)} {
		package require snack
		set pop /usr/share/sounds/gnibbles/pop.wav
		snack::sound pop -file $pop
		set crash /usr/share/sounds/gnibbles/crash.wav
		snack::sound crash -file $crash
	}

	# tick - 16 means every 16 ms, or 60/sec.
	# smaller number means smoother motion, and more work for machine.
	# tick is factored into the ball speed.
	set ob(tick) 16

        # wall width
        set ob(wwid) 52

        # ball size
        set ob(bsize) 27

        # paddle height
        set ob(padh) 32

	# maxhop - we don't want the ball going through the paddle!
	set ob(maxhop) [expr {$ob(bsize) + $ob(padh) - 1}]

        # window dims
        set ob(winwidth) 800
        set ob(winheight) 800

	# centers
	set ob(half,x) [expr {$ob(winwidth) / 2}]
	set ob(half,y) [expr {$ob(winheight) / 2}]
	set cx $ob(half,x)
	set cy $ob(half,y)

	canvas .c -width $ob(winwidth) -height $ob(winheight) -bg black
	.c config -highlightthickness 0
	catch {grid anchor . center}

	label .status -textvariable ob(status) -font default\
	-background $ob(mainbg) -foreground gray50
	status_mes [imes "Press n key to Start, Alt-m for menu"]

	grid .c
	grid .status
	set ob(bigcan) .c

	label .disp -textvariable mob(score)  -font $ob(scorefont) -bg $ob(mainbg) -fg yellow
	place .disp -in . -relx 1.0 -rely 0.0 -anchor ne

        wm attributes . -zoomed 1
        update idletasks

        . config -bg $ob(mainbg)

	domenu

	make_walls

	make_paddles

	set_paddles
 
	# inner field
	# make this after walls and paddles!
	set ob(field) [.c create rect $ob(pd,w) $ob(pd,n) $ob(pd,e) $ob(pd,s) -outline "" -fill gray30 ]

	# the ball (after field!)
	set bsize $ob(bsize)
	set x1 [expr {$cx - ($bsize / 2)}]
	set x2 [expr {$cx + ($bsize / 2)}]
	set y1 [expr {$cy - ($bsize / 2)}]
	set y2 [expr {$cy + ($bsize / 2)}]
	set ob(ball) [.c create oval $x1 $y1 $x2 $y2 -fill yellow -outline orange -width 5 -tag ball]
	set ob(ballorig) [.c coords $ob(ball)]

	# bind .c <Motion> {dodrag %W %x %y}
	bind . <s> stop_pong
	bind . <n> new_pong
	bind . <q> done
	bind . <Escape> done
        wm protocol . WM_DELETE_WINDOW { done }

	set ob(lastbat) none

	start_rtl

	if {$ob(wrist)} {
		# note, we need to reset this if we use kicks
		# hold ps at origin
		wshm wrist_diff_damp 0.0
		movebox 0 7 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	}
}

proc stop_pong {} {
	global ob mob

	after cancel moveball

	if {$mob(padrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(padrow)
	}

	set str "score=$mob(score) level=$mob(level) padw=$mob(padw)\
		bounces=$mob(bounces) type=$mob(whichgame)"
	game_log_entry stopgame "$str"

	status_mes [imes "Press n key to Start, Alt-m for menu"]
}

# restart each new game

proc new_pong {} {
	global ob mob

	stop_pong

        game_log_entry startgame

	regsub -all {[^0-9]} $mob(endgame) {} mob(endgame)
	set ob(endgame) $mob(endgame)
	regsub -all {[^0-9]} $mob(level) {} mob(level)
	set ob(level) $mob(level)

	eval .c coords $ob(ball) $ob(ballorig)
	set ob(lastbat) none

	array set mob {
		bounces 0
		score  0
		padrow  0
		maxinrow  0
		wall 0
		paddle 0
	}

	set_walls

	make_paddles

	set_paddles
	
	# if the speed is bigger than wall + ball width, we have trouble,
	# because the ball has to hit the walls to stay in bounds.
	# paddle width = 35. ball width = 30
	# tick = 20, level <= 100.
	# so keep forw and side2 < 325, which will keep ball
	# hops less than 65.

	set ob(level) [bracket $ob(level) 1 100]
	# forw <= 80
	set ob(forw)  [expr {$ob(level) * $ob(tick) / 6. }]
	# set ob(forw) [bracket $ob(forw) 1 320]
	set ob(side)  [expr {$ob(level) * $ob(tick) / 3. }]
	# set ob(side) [bracket $ob(side) 1 640]
	set ob(side2) [expr {($ob(side) / 2.0 )}]

	set forw5 [format %.2f [expr {$ob(forw) / 5.0 + 1}]]

	# where does the ball start?  use this order.
	# forw5 is %.2f
	if {$ob(livewall,s)} {
		set ob(dir)   [list 0 $forw5]
	} elseif {$ob(livewall,n)} {
		set ob(dir)   [list 0 [expr {0 - $forw5}]]
	} elseif {$ob(livewall,w)} {
		set ob(dir)   [list [expr {0 - $forw5}] 0]
	} elseif {$ob(livewall,e)} {
		set ob(dir)   [list $forw5 0]
	} else {
		error "no live walls"
	}
	moveball

	status_mes [imes "Press Alt-m for menu"]
}

proc dodrag {w x y} {
	global ob
	if {$ob(livewall,n)} { dragx $w $x pn }
	if {$ob(livewall,s)} { dragx $w $x ps }
	if {$ob(livewall,w)} { dragy $w $y pw }
	if {$ob(livewall,e)} { dragy $w $y pe }
}

proc dragx {w x what} {
	global ob

	set x1 [expr {[.c canvasx $x] - $ob(padw2)}]
	set x2 [expr {$x1 + $ob(padw)}]
	foreach {d1 y1 d2 y2} [.c coords $what] {break}
	.c coords $what $x1 $y1 $x2 $y2

# puts "dragx $what $cl"
}

proc dragy {w y what} {
	global ob

	set y1 [expr {[.c canvasy $y] - $ob(padw2)}]
	set y2 [expr {$y1 + $ob(padw)}]
	foreach {x1 d1 x2 d2} [.c coords $what] {break}
	.c coords $what $x1 $y1 $x2 $y2

# puts "dragy $what $cl"
}

# shake the walls.

proc shake {obj} {
	global ob

	eval .c move $obj 0 10
	after 50 [list eval .c move $obj 10 0 ]

	after 100 [list eval .c move $obj 0 -20 ]
	after 150 [list eval .c move $obj -20 0 ]

	after 200 [list eval .c move $obj 0 10 ]
	after 250 [list eval .c move $obj 10 0 ]
}

# did the ball fall completely off the table?
# this shouldn't happen at reasonable speeds,
# but it's safe to check.

# note: there are still ball off table problems at very high speed.

proc ballofftable {bbox} {
	global ob mob

	foreach {x1 y1 x2 y2} $bbox {break}
	if {
	($x2 < 0) ||
	($x1 > $ob(winwidth)) ||
	($y2 < 0) ||
	($y1 > $ob(winheight)) } {
		# bell
		puts "ball off table, bounces $mob(bounces) bbox $bbox dir $ob(dir)"

		# throw the ball to the center of the table,
		# and send it back at half speed.
		foreach {x y} $ob(dir) {break}
		set bsize $ob(bsize)
		set cx $ob(half,x)
		set cy $ob(half,y)
		set bsize $ob(bsize)
		set x1 [expr {$cx - ($bsize / 2)}]
		set x2 [expr {$cx + ($bsize / 2)}]
		set y1 [expr {$cy - ($bsize / 2)}]
		set y2 [expr {$cy + ($bsize / 2)}]
		.c coords ball $x1 $y1 $x2 $y2
		# slow it down, send it backwards
		set x [expr $x / -2.0]
		set y [expr $y / -2.0]
		set ob(dir) "$x $y"
	}
}

proc getxy {} {
	global ob
	set x [getptr x]
	set y [getptr y]
	if {$ob(wrist)} {
	    foreach {x y} [wrist_ptr_scale $x $y] break
	}
	set x [expr int($ob(scale) * $x + $ob(half,x))]
	set y [expr int(-$ob(scale) * $y + $ob(half,y))]
	list $x $y
}

# the main loop
# note that "find overlapping" returns the objects in display list
# stacking order.  the objects were created in this order: {walls
# paddles field ball} so that if the ball overlaps both paddle and
# field, it will find paddle.

# in the switch, walls may be either live (colored) or not (gray).
# gray walls reflect, and do not change scores.

proc moveball {} {
	global ob mob

	foreach {x y} [getxy] break
	dodrag .c $x $y
# wm title . "$x $y"

	# move ball
	eval .c move ball $ob(dir)
	set mob(balldir) $ob(dir)

	# see if the ball has hit anything - paddle or wall.
	set bbox [.c bbox ball]

	ballofftable $bbox

	set ob(bat) [lindex [eval .c find overlapping $bbox] 0]
# puts "bat $ob(bat) ball $ob(ball)"

	# lastbat hack prevents wobbles
	if {$ob(bat) != $ob(field)
		&& $ob(bat) != $ob(ball)
		&& $ob(bat) != $ob(lastbat)
		} {

		# set new ball velocity
		# forw is directional, (must be negated in switch)
		# side is not
		set forw [expr {(($ob(forw) + \
			[irand $ob(forw)])/10.0)}]
		set side [expr {(0.0 - $ob(side2) + \
			[irand $ob(side)])/10.0}]

		foreach {oxr oyr} $ob(dir) {break}
# puts "bat $ob(bat) n $ob(n) s $ob(s) w $ob(w) e $ob(e)"
		switch $ob(bat) $ob(pad,n) {
# puts "hit pn"
			set xr $side
			set yr $forw
			hitpaddle north
		} $ob(pad,s) {
# puts "hit ps"
			set xr $side
			set yr [expr {0 - $forw}]
			hitpaddle south
		} $ob(pad,w) {
# puts "hit pw"
			set xr $forw
			set yr $side
			hitpaddle west
		} $ob(pad,e) {
# puts "hit pe"
			set xr [expr {0 - $forw}]
			set yr $side
			hitpaddle east


		} $ob(wall,n) {
# puts "hit wn"
			if {$ob(livewall,n)} {
				set xr $side
				set yr $forw
				hitwall
				shake $ob(bat)
			} else {
				set xr $oxr
				set yr [expr {0 - $oyr}]
			}
		} $ob(wall,s) {
# puts "hit ws"
			if {$ob(livewall,s)} {
				set xr $side
				set yr [expr {0 - $forw}]
				hitwall
				shake $ob(bat)
			} else {
				set xr $oxr
				set yr [expr {0 - $oyr}]
			}
		} $ob(wall,w) {
# puts "hit ww"
			if {$ob(livewall,w)} {
				set xr $forw
				set yr $side
				hitwall
				shake $ob(bat)
			} else {
				set xr [expr {0 - $oxr}]
				set yr $oyr
			}
		} $ob(wall,e) {
# puts "hit we"
			if {$ob(livewall,e)} {
				set xr [expr {0 - $forw}]
				set yr $side
				hitwall
				shake $ob(bat)
			} else {
				set xr [expr {0 - $oxr}]
				set yr $oyr
			}

		} default {
			# this sometimes happens when the ball
			# goes off the table.
			set xr $oxr
			set yr $oyr
			puts "moveball switch default, bounces $mob(bounces) bat $ob(bat) dir $ob(dir)"
		}
		
		# set new direction.
		set ob(dir) [format "%.2f %.2f" $xr $yr]
# puts "$forw $side ; $ob(dir)"
		set ob(lastbat) $ob(bat)
		}
	# end of ball hits thing, schedule anew

	if {$ob(endgame) <= 0 || $mob(bounces) < $ob(endgame)} {
		set ob(after) [after $ob(tick) moveball]
		# update idletasks
	} else {
		stop_pong
	}
}

# oops, the ball hit a life wall.

proc hitwall {} {
	global ob mob
	if {$ob(sound)} {
		crash play
	}

	incr mob(bounces)
	incr mob(score) -30
	incr mob(wall)
	if {$mob(padrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(padrow)
	}
	set mob(padrow) 0
        wm title . "Pong    Level: $mob(level)    Score: $mob(score)"
}

# yay, the ball hit a paddle

proc hitpaddle {{dir south}} {
    global ob mob
    if {$ob(sound)} {
	    pop play
    }

    if {!$ob(wrist)} {
	# not workihg yet
	kick $dir
    }
    incr mob(bounces)
    incr mob(paddle)
    incr mob(score) 10
    incr mob(padrow)
    wm title . "Pong    Level: $mob(level)    Score: $mob(score)"
}

# set up the menu (once)

proc domenu {} {
        set m [menu_init .menu]
        menu_v $m whichgame "Game Type (nswe)" nswe
        menu_v $m endgame "Game Length" 100
        menu_v $m padw "Paddle Width" 133
        menu_v $m level "Level (1-100)" 10
        menu_cb $m "round" "Oval Paddles"
        menu_t $m blank "" ""

	menu_t $m bounces Bounces
	menu_t $m score Score
	menu_t $m padrow "Current Streak"
	menu_t $m maxinrow "Longest Streak"
	menu_t $m wall "Wall Hits"
	menu_t $m paddle "Paddle Hits"
	menu_t $m blank2 "" ""

	menu_b $m newgame "New Game (n)" new_pong
	menu_t $m hidemenu "Toggle Menu (Alt-m)" ""
	menu_b $m stopgame "Stop Game (s)" stop_pong
	menu_b $m quit "Exit (q)" {done}
}

proc done {} {
	global ob

	stop_pong

	game_log_entry end [current_robot]

	stop_rtl

	exit
}

init_pong

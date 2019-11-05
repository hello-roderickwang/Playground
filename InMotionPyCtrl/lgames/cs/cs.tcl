#! /usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 9/2000

# cretan square
# a Cretan maze is an ancient design, see for example:
# http://www.gwydir.demon.co.uk/jo/maze/cretan.htm

# Tk GUI library
package require Tk

source ../common/util.tcl
source ../common/menu.tcl

source $::env(I18N_HOME)/i18n.tcl

global ob

font create default -family Times -size -18
option add *font default

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

# is this planar or wrist?
localize_robot

# maze scale
set ob(scale) 25.
# additional cursor scaling, giving us about 20cm square.
set ob(sscale) 9.

set ob(gray) gray20
set ob(mainbg) black

proc Dialog_CS {string} {
    global dcs ob
    set w .dcs
    if {[winfo exists $w]} {destroy $w}
    if [Dialog_Create $w $string -borderwidth 10] {
	checkbutton $w.logdata -text [imes "Log Data"] \
	    -variable ob(dcs,logdata) -relief flat 
	checkbutton $w.sendforces -text [imes "Send Forces"] \
	    -variable ob(dcs,sendforces) -relief flat

	label $w.dummy
	button $w.cancel -text [imes "Cancel"] \
	    -command {set ob(dcs,ok) 0}
	button $w.ok -text [imes "Run"] \
	    -command {set ob(dcs,ok) 1}

	grid $w.logdata -sticky w
	grid $w.sendforces -sticky w
	grid $w.dummy
	grid $w.cancel $w.ok
    }
    set ob(dcs,ok) 0
    Dialog_Wait $w ob(dcs,ok) $w.ok
    Dialog_Dismiss $w
    return $ob(dcs,ok)
}

# called each time a dot is entered,
# this is the big event.
# set up the next dot goal.

proc dot_enter {w} {
	global ob mob env
# puts "dot_enter: ci $ob(ci)"
	# the first dot is the start.
	if {$ob(ci) == 0} {
	    $w itemconfig seg -fill $ob(gray)
	    $w raise seg
	    clock_start
	    if {$ob(savelog)} {
		set nlog 8
		set logfnid 0
		switch [current_robot] {
		    planar {
			set nlog 8
			set logfnid 0
		    }
		    wrist {
			set nlog 11
			set logfnid 8
		    }
		}
		g_log_start cs [fnstring $env(PATID)] therapy $nlog $logfnid
		set_log_timer
	    }
	}

	# last dot is stop.
	if {$ob(ci) == $ob(lastdot)} {
		log_timeout
		clock_stop
		glog "time $mob(time)"
	}

	# most cases:

	# color old
	set color [lindex $ob(rainbow) [expr {($ob(ci) -1) % 7} ]]
	$w itemconfig seg,$ob(ci) -fill $color
	if $ob(sound) {click play}
	# $w bind dot,$ob(ci) <Enter> {}

	# color new
	set oci $ob(ci)
	incr ob(ci)
	$w raise seg,$ob(ci)
	# $w bind dot,$ob(ci) <Enter> {dot_enter %W}
	$w raise seg,$oci
	$w raise dot,$ob(ci)
	$w raise cursor
	if {$ob(ci) >= $ob(ncslines)} { 
		mazedone .c
	} else {
		newslot $ob(ci)
	}
}

# we're done.
proc mazedone {w} {
	global ob mob

# puts "mazedone"
	if $ob(sound) {yay play}
	catch {
	    log_timeout
	    clock_stop
	}
	$w raise seg
	$w raise cursor

	game_log_entry stopgame "time $mob(time)"

	if {$ob(ci) >= $ob(ncslines)} { 
		dazzle $w 5 200
	}

	set ob(ci) 0
	set ob(running) 0
	stop_movebox 0
	status_mes [imes "Press n key to Start, Alt-m for menu"]
}

# jiggle the colors on all the path segments.

proc dazzle {w n wait} {
	global ob
# puts "dazzle $n"
	if {![info exists ob(dazzle,n)]} {
		set ob(dazzle,n) $n
	} else {
		incr n -1
	}

	for {set i 1} {$i <= $ob(ncslines)} {incr i} {
		set color [lindex $ob(rainbow) [irand 7]]
		$w itemconfig seg,$i -fill $color
	}
	if {$n > 0} {
		after $wait dazzle $w $n $wait
	} else {
		unset ob(dazzle,n)
	}
}

proc cur_loop {w} {
# the cursor motion loop, runs 20x/sec
    global ob mob

    # 20x / sec
    after 50 cur_loop $w

    # get coords in world space meters
    set x [getptr x]
    set y [getptr y]

    if {$ob(wrist)} {
	foreach {x y} [wrist_ptr_scale $x $y] break
    }

    set ob(cur,world,x) $x
    set ob(cur,world,y) $y

    # move the yellow cursor ball, scale, and flip its y
    set ob(cur,can,x) [expr {$x * $ob(scale) * $ob(sscale)}]
    set ob(cur,can,y) [expr {-$y * $ob(scale) * $ob(sscale)}]
    $w coords cursor [centxy $ob(cur,can,x) $ob(cur,can,y) .5]
    $w scale cursor 0 0 $ob(scale) $ob(scale)

    wm title . "Cretan Square Maze    Time: $mob(time)"

    # wm title . "x $x y $y cx $ob(cur,can,x) cy $ob(cur,can,y)"

    # no check for ball hit if target not blinking.
    if {$ob(running) == 0} {
        return
    }

    # see if the cursor is close enough to nextball
    foreach {x1 y1} [centertag $w cursor] break
    foreach {x2 y2} [centertag $w dot,$ob(ci)] break
    set dist [edist $x1 $y1 $x2 $y2]
    if {$dist < 30} {
        # puts "hit: $ob(ci) $x1 $y1 $x2 $y2  edist: $dist"
        dot_enter $w
    }
}

# set up the maze to play again

proc reset {w} {
	global ob
# puts "reset"
	$w raise seg
	# $w itemconfig seg,1 -fill $ob(gray)

	# $w bind dot,0 <Enter> {dot_enter %W}
	$w raise dot,0
	$w raise cursor

	set ob(ci) 0
	set ob(running) 1
	
}

# stop clock, jiggle colors, reset maze.

proc restart {} {
	global ob
# puts "restart"
	set w .c
	catch {
	    log_timeout
	    clock_stop
	}
	if {$ob(running)} {
		mazedone .c
	}
	game_log_entry startgame
	# this takes a second.
	dazzle $w 5 200

	after 1200 {
		global ob
		set w .c
		reset $w
		center_arm $ob(slot,1,startx) $ob(slot,1,starty)
	}
	status_mes [imes "Press Alt-m for menu"]
}

# the main program

# note: modify this to make the dots be of variable size.
# tuck the dots under a new black cover.

proc cretansquare {} {
	global ob env
# puts "cretansquare"
	# no effect, no_arm not coded yet.
	# no_arm

	set ob(programname) maze

	set ob(running) 0
	set ob(sound) 0

	if {$ob(sound)} {
		package require snack
	}

	set ob(rainbow) {red orange yellow green4 blue magenta4 magenta}

        wm attributes . -zoomed 1
        update idletasks
        wm withdraw .

        set ob(motorforces) 0
        set ob(savelog) 0

	set ob(asklog) 1
	if {$ob(asklog)} { 
	    if {![info exists env(PATID)]} {
		error "Please enter a Patient ID"
		exit
	    }
	    if {$env(PATID) == ""} {
		error "Please enter a Patient ID"
		exit
	    }
	    set ret [Dialog_CS "Cretan Square Maze Setup"]
	    if {$ret == 0} {
		exit
	    }
	    if {$ob(dcs,sendforces)} {
		set ob(motorforces) 1
	    }
	    if {$ob(dcs,logdata)} {
		set ob(savelog) 1
	    }
	}
	set ob(patname) [fnstring $env(PATID)]
	set ob(logdirbase) $env(THERAPIST_HOME)
	game_log_entry begin

	if $ob(sound) {
		set click /usr/share/sounds/gnibbles/pop.wav
		set yay /usr/share/sounds/gnobots2/victory.wav

		snack::sound click -file $click
		snack::sound yay -file $yay
	}

	# I realize that this point list is redundant.
	# give me a break.
	set ocretansquare {
	1 29
	13 29  13 23   5 23   5  5  25  5  25 25
	17 25  17 27  27 27  27  3   3  3   3 25
	11 25  11 27   1 27   1  1  29  1  29 29
	15 29  15 23  23 23  23  7   7  7   7 21
	13 21  13 13  17 13  17 19  19 19  19 11
	11 11  11 19   9 19   9  9  21  9  21 21
	15 21  15 15
	}

	# this one is zero-centered, a good thing.
	set cretansquare {
	-14 -14
	-2 -14 -2 -8 -10 -8   -10 10 10 10 10 -10
	2 -10 2 -12 12 -12    12 12 -12 12 -12 -10
	-4 -10 -4 -12 -14 -12 -14 14 14 14 14 -14
	0 -14 0 -8 8 -8 8     8 -8 8 -8 -6
	-2 -6 -2 2 2 2        2 -4 4 -4 4 4
	-4 4 -4 -4 -6 -4      -6 6 6 6 6 -6
	0 -6 0 0
	}

        wm deiconify .
        set width [winfo width .]
        set height [winfo height .]
	# account for status line
        set height [expr {$height - 30}]
        . config -bg $ob(mainbg)


	# count the line segments
	set ob(ncslines) [expr {[llength $cretansquare] / 2}]

	# lay out the basic grid of line segments and dots.
	# an initial dot, then a set of segments terminated by dots.

        canvas .c -width $width -height $height -bg $ob(mainbg)
        .c config -highlightthickness 0
        set w .c
        set ob(bigcan) .c
        set ob(half,x) [expr {int($width/2)}]
        set ob(half,y) [expr {int($height/2)}]
        # pack $w -fill both -expand no
        catch {grid anchor . center}

	label .status -textvariable ob(status) -font default\
	-background $ob(mainbg) -foreground gray50
	status_mes [imes "Press n key to Start, Alt-m for menu"]

        $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x) $ob(half,y)]
        grid $w
	grid .status

	set i 0
	foreach {p1 p2} $cretansquare {

		# except for the first dot.
		if {$i != 0} {
			# create a line from the last dot,
			set lscale [expr {$ob(scale) * 1.2}]
			$w create line $lastp1 $lastp2 $p1 $p2 -width $lscale \
				-capstyle round -fill $ob(gray) \
				-tags [list seg,$i seg]
			$w lower seg,$i

			set scale [expr {$ob(scale) * $ob(sscale)}]
			# record world slot position from the last dot
			set ob(slot,$i,startx) [expr $lastp1 / $scale]
			set ob(slot,$i,starty) [expr $lastp2 / $scale]
			set ob(slot,$i,endx) [expr $p1 / $scale]
			set ob(slot,$i,endy) [expr $p2 / $scale]
		}

		# create a dot and hide it under the line
		$w create oval [centxy $p1 $p2 .5] -fill orange \
			-outline blue -width 2 -tags [list dot,$i dot]
		$w lower dot,$i


		set lastp1 $p1
		set lastp2 $p2
		incr i
	}
	# exception
	$w lower dot,0

	set ob(lastdot) [incr i -1]
	$w addtag lastdot withtag dot,$i
	$w addtag firstdot withtag dot,0

	# create cursor off center
	# will soon be at actual cursor position after mouse motion
	set ob(cursor,id) [$w create oval [centxy 0 0 .5] -tags cursor\
	-fill yellow]

	$w scale all 0 0 $ob(scale) -$ob(scale)

	set m [menu_init .menu]
	menu_t $m time "Time"
	menu_t $m b0 "" ""
	menu_b $m start "New Game (n)" restart
	menu_t $m menu "Toggle Menu (Alt-m)" ""
	menu_b $m stop "Stop Game (s)" "mazedone .c"
	menu_b $m quit "Exit (q)" done

	bind . <q> done
	bind . <Escape> done
	wm protocol . WM_DELETE_WINDOW { done }

	bind . <s> {mazedone .c}
	bind . <d> {dazzle .c 5 200}
	bind . <n> restart

	start_rtl
	after 100
	wshm damp 5.0
	wshm stiff 300.0
	wshm wrist_diff_stiff 20.0

	label .disp -textvariable mob(time) -font $ob(scorefont) -bg $ob(mainbg) -fg yellow
	place .disp -in . -relx 1.0 -rely 0.0 -anchor ne


	cur_loop $w
}

proc newslot {i} {
	global ob
# puts "newslot $i"

	if {!$ob(motorforces)} {
		stop_movebox
		return
	}

	set x1 $ob(slot,$i,startx)
	set y1 $ob(slot,$i,starty)
	set x2 $ob(slot,$i,endx)
	set y2 $ob(slot,$i,endy)
	set dist [edist $x1 $y1 $x2 $y2]
	set ticks [expr {int($dist * 4000.)}]
	# puts "dist $dist ticks $ticks"
	# puts "movebox 0 0 {0 $ticks 1} {$x1 $y1 0. 0.} {$x2 $y2 0. 0.}"
	# movebox 0 4 {0 $ticks 1} {$x1 $y1 0. 0.} {$x2 $y2 0. 0.}
	set ctl 4
	set mbsrc [list $x1 $y1 0.0 0.0]
	if {$ob(wrist)} {
	    set ctl 7
	    set mbsrc [point_to_collapse [list $x1 $y1 0.0 0.0] [list $x2 $y2 0.0 0.0]]
	}

	# puts "movebox 0 $ctl {0 $ticks 1} $mbsrc {$x2 $y2 0. 0.}"
	movebox 0 $ctl {0 $ticks 1} $mbsrc {$x2 $y2 0. 0.}
}

# process all log_stops, including timeouts or other end of game
proc log_timeout {} {
    global ob

    if {!$ob(savelog)} {return}

    if {[info exists ob(log_timer_id)]} {
        after cancel $ob(log_timer_id)
        unset ob(log_timer_id)
        # exec beep
        # puts "log_timeout"
        g_log_stop
    }
}

proc set_log_timer {} {
    global ob

    if {!$ob(savelog)} {return}

    if {[info exists ob(log_timer_id)]} {
        # clear old one
        log_timeout
    }
    # set new one
    set ob(log_timer_id) [after 30000 log_timeout]
}

proc done {} {
	global ob mob
	game_log_entry stopgame "time $mob(time)"
	game_log_entry end [current_robot]
	if {$ob(wrist)} {
		wdone
	}
	stop_rtl
	exit
}

cretansquare

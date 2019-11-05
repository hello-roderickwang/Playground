#! /usr/bin/wish

# Copyright 2000-2014 Interactive Motion Technologies, Inc
# trb 9/2000

# clean the window with a squeegee, to revel a picture

package require Tk
package require Img

font create default -family Times -size -18
option add *font default

source ../common/util.tcl
source ../common/menu.tcl
source $::env(I18N_HOME)/i18n.tcl

global ob

# if you want squeegee to provide facilities for saving log data,
# set ob(asklog) 1
set ob(asklog) 0

set ob(crobhome) $::env(CROB_HOME)
set ob(lgameshome) $::env(LGAMES_HOME)

source $ob(crobhome)/shm.tcl

# is this planar or wrist?
localize_robot

proc every {ms body} {eval $body; after $ms [info level 0]}

# squeegee program
# like clearing the frost off a window.

# mouseenter - make sure goofy mouse enter doesn't mess up drawing.

proc mouseenter {} {
	global ob
	set ob(lastx) -1
	set ob(lasty) -1
}

# mousemove - where the action is, this is what needs to be efficient.
# drag the brush around the screen in response to mouse motion.
# x1 and y1 factor into the x2 y2 calculation,
# and are used as lastx and lasty next time.

proc mousemove {x1 y1 w} {
	global mob ob

	set iw $ob(iw)
	set ih $ob(ih)

	# calculate the brushstroke area.
	# the +1 is important, so we don't skip rasters

	# set x1 [bracket $x1 -1 $iw]
	# set x2 [expr {$x1 + $mob(brushw) +1}] 
	# set x2 [bracket $x2 0 $iw]

	# set y1 [bracket $y1 -1 $ih]
	# set y2 [expr {$y1 + $mob(brushh) +1}] 
	# set y2 [bracket $y2 0 $ih]

	set x1 [bracket $x1 0 $iw]
	set x2 [expr {$x1 + $mob(brushw) +1}] 
	set x2 [bracket $x2 0 $iw]

	set y1 [bracket $y1 0 $ih]
	set y2 [expr {$y1 + $mob(brushh) +1}] 
	set y2 [bracket $y2 0 $ih]

	set lastx $ob(lastx)
	set lasty $ob(lasty)
	set ob(lastx) $x1
	set ob(lasty) $y1

	# if there is no image, don't draw this iteration
	if {$ob(color) == "none"} {
		return
	}

	# first trip, or cursor off screen, don't draw this iteration
	if {$lastx == -1 || $lasty == -1} {
		return
	}

	# draw the delta from last
	$ob(gray) copy $ob(color) \
		-from $lastx $lasty $x2 $y2 \
		-to   $lastx $lasty $x2 $y2

	# also stamp
	$ob(gray) copy $ob(color) \
		-from $x1 $y1 $x2 $y2 \
		-to   $x1 $y1 $x2 $y2

	$w coords brush $x1 $y1 $x2 $y2

	if {$ob(imdone)} { return }

	# don't call dogrid after the clock stops
	dogrid $x1 $y1
}

# keep a map of where the user has dragged the squeegee, so we can
# finish when the entire area has been pretty much covered.

# for instance, if an image is 800x600, and the cursor is at 250x350,
# then leftbox(2,3) gets set, and the entries in leftbox get counted
# to generate a percentage.

proc dogrid {x1 y1} {
	global ob mob leftbox rightbox

	set ybox [expr {int($y1 / $ob(gridy))}]
	set xbox [expr {int($x1 / $ob(gridx))}]

	# left or right side?
	if {$xbox < $ob(cbox)} {
		set leftbox($xbox,$ybox) 1
		set mob(lfilled) [expr {(100 * [array size leftbox]) / $ob(nboxes)}]
	} else {
		set rightbox($xbox,$ybox) 1
		set mob(rfilled) [expr {(100 * [array size rightbox]) / $ob(nboxes)}]
	}

	set mob(filled) [expr {($mob(lfilled) + $mob(rfilled)) / 2}]

	if {$mob(filled) >= 100} {
		doneimage 3000
	}
}

# stops the clock, but gives the patient 3 more seconds
# to put on finishing touches.
# then color it all in.

proc finishing_touch {} {
	global ob

	# go to the next image after 10 seconds
	after 10000 doneimage_timeout

	# has the gray image already been deleted?
	if {![info exists ob(color)]} return
	if {$ob(color) == "none"} return

	$ob(gray) copy $ob(color)
}

proc doneimage_timeout {} {
	newimage .c
}

proc doneimage {msec} {
	global ob mob
	set ob(imdone) 1

	log_timeout
	clock_stop
	glog "time $mob(time)"
	game_log_entry stopgame
	# squeaky clean
	after $msec finishing_touch
}

proc newcurs {w} {
	global mob
	$w create rect 0 0 $mob(brushw) $mob(brushh) \
		-width 2 -outline blue4 -tags brush
	# puts "newcurs brush $mob(brushw) $mob(brushh) -outline red"
}

proc do_graphicsmagick {image} {
        global ob
        catch {exec $ob(lgameshome)/squeegee/squee $image} ret
        return $ret
}

# read in a new photo image
# there is a full color image and a corresponding dull gray image,
# when you move the mouse, it's like cleaning the frost off a window,
# copying corresponding pixels from the color image to the gray image.

proc newimage {w} {
	global ob mob env
	global leftbox rightbox

	after cancel doneimage_timeout
	game_log_entry startgame

	delimage $w

	set ob(imdone) 0


	set ifile [lindex $ob(flist) [irand [llength $ob(flist)]]]
	set ob(ifile) $ifile
	wm title . $ifile

        foreach {ob(cfile) ob(gfile)} [do_graphicsmagick $ifile] break

	set ob(gray) [image create photo -file $ob(gfile)]
	set ob(color) [image create photo -file $ob(cfile)]
	$w create image 0 0 -image $ob(gray) -anchor nw
        file delete $ob(cfile)
        file delete $ob(gfile)

	# image width and height and positionn
	set ob(iw) [image width $ob(color)]
	set ob(ih) [image height $ob(color)]
	set ob(iw2) [expr {$ob(iw) / 2}]
	set ob(ih2) [expr {$ob(ih) / 2}]
	set ob(half,x) $ob(iw2)
	set ob(half,y) $ob(ih2)
	set iw $ob(iw)
	set ih $ob(ih)
	set ob(lastx) -1
	set ob(lasty) -1

	set ob(gridx) [expr {double($ob(iw) + 1)/ 8}]
	set ob(gridy) [expr {double($ob(ih) + 1)/ 6}]
	# number of boxes on each side
	set ob(nboxes) 24
	# center box
	set ob(cbox) 4

	$w configure -height $ih -width $iw

        . config -bg $ob(mainbg)

	set mob(filled) 0
	set mob(lfilled) 0
	set mob(rfilled) 0

	$w raise brush

	arrayunset leftbox rightbox

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
	    g_log_start squeegee [fnstring $env(PATID)] therapy $nlog $logfnid
	    set_log_timer
	}
	clock_start
	status_mes [imes "Press n key for new picture, Alt-m for menu"]
}


# clear the old photo image
proc delimage {w} {
	global ob

	after cancel finishing_touch

	if {![info exists ob(color)]} return
	if {$ob(color) == "none"} return

	set im $ob(color) 
	set ob(color) none
	image delete $im

	set im $ob(gray) 
	set ob(gray) none
	image delete $im

	log_timeout
}

proc Dialog_Squeegee {string} {
    global ob
    set w .dsqueegee
    if {[winfo exists $w]} {destroy $w}
    if [Dialog_Create $w $string -borderwidth 10] {

	label $w.picset_label -text "Choose Picture Set"
	grid $w.picset_label

	# grid $w.picset -sticky w
	set ob(pic,basedir) [file join $::env(IMAGES_HOME) squeegee]
	foreach d [glob -join $ob(pic,basedir) *] {
		lappend ob(picdirlist) [file tail $d]
	}
	set ob(picdirlist) [lsort $ob(picdirlist)]

	set ob(pic,picdir) euroart
	foreach picdir $ob(picdirlist) {
            radiobutton $w.b_pic_set_$picdir -text "$picdir" \
                -variable ob(pic,picdir) -relief flat -value $picdir
	    grid $w.b_pic_set_$picdir -sticky w
	}

        button $w.cancel -text Cancel \
            -command {set ob(dsqueegee,ok) 0}
        button $w.ok -text Run \
            -command {set ob(dsqueegee,ok) 1}
	grid $w.cancel $w.ok
    }

    Dialog_Wait $w ob(dsqueegee,ok) $w.ok

    if {$ob(dsqueegee,ok) && ($ob(pic,picdir) == "wyland")} {
	tk_messageBox -message "Wyland images are © 2010 Wyland Worldwide, LLC, used by agreement.\n                Wyland.com"
    }

    Dialog_Dismiss $w
    return $ob(dsqueegee,ok)
}

# the main program

proc squeegee {} {
	global leftbox rightbox
	global mob ob env

	set ob(programname) squeegee
	set ob(logdirbase) $::env(THERAPIST_HOME)

	set ob(mainbg) black

        wm attributes . -zoomed 1
        update idletasks
        wm withdraw .
        set ob(savelog) 0
        if {$ob(asklog)} {
            if {![info exists env(PATID)]} {
                error "Please enter a Patient ID"
            }
            if {$env(PATID) == ""} {
                error "Please enter a Patient ID"
            }
            set ret [tk_dialog .dial "Logging" "Would you like to save log data?" "" 1 "Yes" "No"]
            # 0 is yes (save)
            if {$ret == 0} {
                set ob(savelog) 1
            }
        }

	set ob(patname) [fnstring $env(PATID)]

	set ret [Dialog_Squeegee "Squeegee Setup"]
	if {$ret == 0} {
	    exit
	}

	set ob(loaded) 1
	# no_arm
	start_rtl
	after 100
        
	# image photo file list
        set ob(flist) [glob -join $ob(pic,basedir) $ob(pic,picdir) *.{jpg,gif,png}]

	# buy a canvas
	set w [canvas .c]
	$w config -highlightthickness 0

	set ob(bigcan) $w
	set ob(scale) 4000.0

	catch {grid anchor . center}

	label .status -textvariable ob(status) -font default\
		-background $ob(mainbg) -foreground gray50
		status_mes [imes "Press n key for new picture, Alt-m for menu"]

	grid $w
	grid .status
	# wm geometry . +50+50

	# keyboard events bound to dot
	# image procs take the canvas
	# clock cursor while you wait.

	bind . <n> { newimage .c }
	bind . <Key-space> { newimage .c }

	# make the brush vertical
	bind . <i> {
		set mob(brushh) 80
		set mob(brushw) 1
	}
	# make the brush horizontal
	bind . <Key-minus> {
		set mob(brushh) 1
		set mob(brushw) 80
	}
	# make the brush square
	bind . <o> {
		set mob(brushh) 80
		set mob(brushw) 80
	}
	# show the finished image
	bind . <c> {doneimage 0}
	# quit
	bind . <q> done
	bind . <Escape> done
        wm protocol . WM_DELETE_WINDOW done

	# the menu

	set m [menu_init .menu]
	menu_v $m brushw "Brush Width"
	menu_v $m brushh "Brush Height"
	menu_t $m b0 "" ""
	menu_t $m time "Time"
	menu_t $m filled "Percent filled"
	menu_t $m lfilled "Percent left filled"
	menu_t $m rfilled "Percent right filled"
	menu_t $m b1 "" ""
	menu_t $m shapes "Brush Shapes (i/-/o)" ""
	menu_t $m show "Show Picture (c)" ""
	menu_t $m b2 "" ""
	menu_b $m new "New Picture (n)" {newimage .c}
	menu_t $m menu "Toggle Menu (Alt-m)" ""
	menu_b $m bye "Exit (q)" {log_timeout; stop_rtl;exit}

	# these are height/width constants for the brush size
	# the brush must be a rectangle.
	# try 2x80 80x2 40x40 80x80
	set mob(brushh) 1
	set mob(brushw) 80

	game_log_entry begin

	# first trip through, rest is event driven.
	newimage $w
	newcurs $w

	# 60x/sec
	every 16 "tick $w"
	set ob(blinkbrushi) 0
	every 400 "blinkbrush $w"
	wm deiconify .
}

proc tick {w} {
	global ob

	set x [getptr x]
	set y [getptr y]
	if {$ob(wrist)} {
	    foreach {x y} [wrist_ptr_scale $x $y] break
	}
	set x [expr int($ob(scale) * $x + $ob(iw2))]
	set y [expr int(-$ob(scale) * $y + $ob(ih2))]
	# wm title . "cursor pos $x $y"

	mousemove $x $y .c
}

proc blinkbrush {w} {
	global ob mob
	if {$ob(blinkbrushi)} {
		set color blue4
		set ob(blinkbrushi) 0
	} else {
		set color yellow
		set ob(blinkbrushi) 1
	}
	$w itemconfig brush -outline $color
	set savestr ""
	if {$ob(savelog)} {set savestr "  (saving log) "}
	wm title . "$ob(cfile) $savestr Time:  $mob(time)"
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
	game_log_entry end [current_robot]
	log_timeout
	stop_rtl
	exit
}

squeegee

#! /usr/bin/tclsh

# pm display
# shows 5 metrics
# hide or show each metric
# remember hide/show state on exit/entry
# use red yellow green1 for <60 <80 >=80

# to test this, make a file /tmp/foo with the contents
# a 1 b 2 c 3 d 4 e 5
# then: gppm2.tcl /tmp/foo

package require Tk
package require BLT
 
source $env(LGAMES_HOME)/common/util.tcl

set curr_rob [current_robot]

set patident default
if {[info exists ::env(PATID)]} {
	set patident $::env(PATID)
}

# write "hide score" data to file, then exit

proc do_exit {} {
    hide_to_file
    exit
}

# print hide array, for debugging

proc phide {type n} {
    puts "$type $n"
    parray ::hide
    puts ""
}

# hide a score, when clicked

proc hide {w n} {
    # puts "hiding $w $n"
    grid remove $w.f.dpy
    set ::hide($n) 1
    # phide hide $n
}

# show a score, when clicked

proc show {w n} {
    # puts "showing $w $n"
    grid $w.f.dpy
    if {[info exists ::hide($n)]} {
	unset ::hide($n)
    } else {
	return
    }
    # phide show $n
}

# help message display

proc help {w n} {

    set htext(1) "Robot Initiate: How often did the robot initiate the motion?  Number of motions out of 80."
    set htext(2) "Distance from Target: How close did the patient come to the target?  Minimum distance in millimeters from the target, average per slot."
    set htext(3) "Robot Power: How much moving power was provided by the robot, rather than by the patient?  Average milliwatts of power, average per slot."
    set htext(4) "Motion Jerk: How rough was the patient's motion?  Average meters (not mm) per second cubed, average per slot."
    set htext(5) "Distance from Straight Line: How far did the patient stray from the intended path?  Average distance in millimeters from the path, average per slot."

    if {$::curr_rob == "wrist"} {
	set htext(1) "Robot Initiate: How often did the robot initiate the motion?  Number of motions out of 80."
	set htext(2) "Distance from Target: How close did the patient come to the target?  Minimum distance in degrees from the target, average per slot."
	set htext(3) "Robot Power: How much moving power was provided by the robot, rather than by the patient?  Average milliwatts of power, average per slot."
	set htext(4) "Motion Jerk: How rough was the patient's motion?  Average radians per second cubed, result divided by 100, average per slot."
	set htext(5) "Distance from Straight Line: How far did the patient stray from the intended path?  Average distance in degrees from the path, average per slot.  (Not used for one-dimensional pronation/supination game.)"
    }

    tk_messageBox -message $htext($n) -title Help
}

# sync the hide state with a hide list (probably read from a file)

proc hidesync {new_hide_list} {
    array set new_hide $new_hide_list
    foreach n {1 2 3 4 5} {
	if {[info exists new_hide($n)]} {
	    hide .pm$n $n
	} else {
	    show .pm$n $n
	}
    }
}

# save the hide array to a file, to be recalled on a future run.

proc hide_to_file {} {
    set fd [open $::hidefile w]
    puts $fd [array get ::hide]
    close $fd
}

# recall the hide array from a file, from a past run.
# if it's not there, show all.

proc hide_from_file {} {
    if {[file readable $::hidefile]} {
	set fd [open $::hidefile]
	gets $fd new_list
	close $fd
    } else {
	set new_list {}
    }
    hidesync $new_list
}

# hide all scores

proc hideall {} {
    foreach n {1 2 3 4 5} {
	hide .pm$n $n
    }
}

# show all scores

proc showall {} {
    foreach n {1 2 3 4 5} {
	show .pm$n $n
    }
}

# set a pm value, and show its score
# displays 1 value large, 4 values smaller
# assume they are 3 digits or less

proc pmsetval {n list color} {
    set str $list
    .pm$n.f.dpy config \
	-font "Helvetica 72" -width 4 -bg white -text $str -bg $color
    if {$color == "blue"} { .pm$n.f.dpy config -fg gray85 }
}

proc pmchartval {n plist color} {
    .pm$n.f.dpy element create BAR -xdata {1 2 3 4} -ydata $plist \
	-fg $color -borderwidth 4
}

# the bars are numbered 1-4, so the numbering is not zero-based.

proc read_file {fn} {
    global barr

    set fd [open $fn r]
    set n 1
    while {[gets $fd line] >= 0} {
	foreach i {1 3 5 7 9} {
	    set k [expr {$i / 2 + 1}]
	    # reading into 1 2 3 4 5
	    set barr($n,$k) [lindex $line $i]
	}
	incr n
    }
    incr n -1
    close $fd
    return $n
}

proc gppm {fn {print screen}} {
    global barr env

    bind . <q> do_exit
    bind . <Q> do_exit
    bind . <Escape> do_exit

    set ::hidefile $env(THERAPIST_HOME)/$env(PATID)/pmhide.txt

    set nlines [read_file $fn]

    # menu button frame along top edge

    frame .mframe
    button .mframe.quit -text Quit -command do_exit
    button .mframe.hideall -text "Hide All"  -command hideall
    button .mframe.showall -text "Show All"  -command showall
    label .mframe.label -textvariable ::framelabel
    grid .mframe - - -sticky ew
    pack .mframe.quit .mframe.hideall .mframe.showall -side left
    pack .mframe.label -side right
    set ::framelabel "$::patident    [clock format [file mtime $fn]]  "

    # 5 labelframes for pm score displays

    foreach n {1 2 3 4 5} {
        labelframe .pm$n -relief ridge -borderwidth 5 -bg gray85 -font {Helvetica 14 bold}
    }

    # we have a configuration like this: -||-
    # with active power double high in middle
    # careful use of -uniform and -weight ensures
    # even sizes and that they don't wiggle when hidden

    grid .pm1 .pm3 .pm4 -sticky news
    grid .pm2 ^ .pm5 -sticky news
    grid rowconfigure . "1 2" -uniform r1 -weight 1
    grid columnconfigure . "0 1 2" -uniform c1 -weight 1

    foreach n {1 2 3 4 5} {
	frame .pm$n.f -relief ridge -borderwidth 10

	if {$nlines == 1} {
	    label .pm$n.f.dpy -font "Helvetica 72" -width 4
	} else {
	    blt::barchart .pm$n.f.dpy
	    .pm$n.f.dpy config -width 3i -height 2i
	    .pm$n.f.dpy xaxis config -subdivisions 1
	    .pm$n.f.dpy legend config -hide yes
        }

	grid .pm$n.f - -
	grid .pm$n.f.dpy
	button .pm$n.hide -text hide -command [list hide .pm$n $n]
	button .pm$n.show -text show -command [list show .pm$n $n]
	button .pm$n.help -text help -command [list help .pm$n $n]
	grid .pm$n.hide .pm$n.show .pm$n.help
	grid rowconfigure .pm$n "0" -uniform r2 -weight 4
	grid rowconfigure .pm$n "1" -uniform r2 -weight 1
	catch {grid anchor .pm$n center}
    }

    # framelabel names

    if {$::curr_rob == "wrist"} {
	.pm1 configure -text "Robot Initiate (count)"
	.pm2 configure -text "Distance from Target (deg)"
	.pm3 configure -text "Robot Power (mWatts)"
	.pm4 configure -text "Motion Jerk ((rad/sec^3)/100)"
	.pm5 configure -text "Distance from Straight Line (deg)"
    } else {
	.pm1 configure -text "Robot Initiate (count)"
	.pm2 configure -text "Distance from Target (mm)"
	.pm3 configure -text "Robot Power (mWatts)"
	.pm4 configure -text "Motion Jerk (m/sec^3)"
	.pm5 configure -text "Distance from Straight Line (mm)"
    }

    # this is tricky to automate, so just wing it
    wm geometry . 1024x768+150+150

    # without this update, the frames don't init correctly ;(

    update idletasks

    # init screen state from "hide" file

    hide_from_file

    set colors {black red green1 blue magenta cyan}

    foreach dpy {1 2 3 4 5} {
	set plist {}
	for {set line 1} {$line <= $nlines} {incr line} {
	    lappend plist $barr($line,$dpy)
	}
	if {$nlines == 1} {
	    pmsetval $dpy $plist [lindex $colors $dpy]
	} else {
	    pmchartval $dpy $plist [lindex $colors $dpy]
	}
    }
    # kludge to make it looks less awful when bars appear behind numbers
    if {$nlines == 4} {
	hideall
	after 500 hide_from_file
    }
}

gppm [lindex $argv 0] [lindex $argv 1]

#! /usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 9/2000

# rtilinux port 2/2005

# racer game

# add bonus coins?

# normal level is 5.  it can be a decimal fraction!

# Tk GUI library
package require Tk

global ob

font create default -family Times -size -18
option add *font default

source ../common/util.tcl
source ../common/menu.tcl

source $::env(I18N_HOME)/i18n.tcl

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

# is this planar or wrist?
localize_robot

# this game does not use hand.
# if it's planarhand, just use planar
if {$ob(planarhand)} {
	set ob(planarhand) 0
	set ob(planar) 1
}

# for balto ankle
source ../race/race.config
# end for balto

proc rancolor {} {
	set rainbow {red orange yellow green4 blue magenta4 magenta}
	lindex $rainbow [irand 7]
}

proc do_title {} {
	global ob mob
	wm title . "Race    Level: $mob(level)    Gates $mob(gates_created)    Score: $mob(score)    Hit left $mob(left)    Hit right $mob(right)"
}

proc del_marks {} {
	.c delete mark
	.c delete marka
}

# make a new gate every 2-3 sec
proc do_gate {} {
    global ob mob
    
    # if we don't do this up here, then the last log file isn't stopped.
    set nstime [expr {int($ob(newgaterate)/2)}]
    set stlogtime [expr {$nstime - 20}]
    if {$ob(savelog)} {
	after $stlogtime stop_log
    }
    after $stlogtime del_marks
    
    if {!$ob(running) || $mob(gates_created) >= $ob(endgame)} {
	return
    }
    
    set i [expr {$mob(gates_created) % $ob(endgame)}]
    set spacing [expr {($ob(winwidth) - ($ob(side2) + $ob(gatew)))/double($ob(npos)-1)}]
    set randi [lindex $ob(gate_list) $i]
    # set randi [expr {$i % $ob(npos)}]
    set x1 [expr {$ob(side) - $ob(half,x) + $spacing * $randi}]
    set x2 [expr {$x1 + $ob(gatew)}]
    set gate_edge_width 0.008
    set x1a [expr {$x1 - $gate_edge_width}]
    set x2a [expr {$x2 + $gate_edge_width}]
    set ob(cen) [expr {($x1 + $x2) / 2.}]
    set col [rancolor]
    # swaps handles swapping x and y coordinates for horizontal motion
    
    eval set r [.c create rect [swaps -.2 .185 $x1 .2]]
    # color $col
    if {$ob(ankle)} {
	set col gray20
    }
    .c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
    eval set r [ .c create rect [swaps $x2 .185 .2 .2]]
    .c itemconfig $r -outline "" -fill $col -tag [list falling gate right g$i]
    
    if {$ob(ankle)} {
	set col [rancolor]
	eval set r [.c create rect [swaps $x1a .185 $x1 .2]]
	.c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
	
	eval set r [.c create rect [swaps $x2 .185 $x2a .2]]
	.c itemconfig $r -outline "" -fill $col -tag [list falling gate left g$i]
    }
    
    .c scale g$i 0 0 $ob(scale) -$ob(scale)
    after $ob(delgaterate) del_thing g$i
    incr mob(gates_created)
    do_title
    
    after $nstime newslot $ob(cen) $i $randi $ob(prevrandi)
    after $ob(newgaterate) do_gate
# puts "randi $randi center $ob(cen) spacing $spacing gatew $ob(gatew)"
    set ob(prevrandi) $randi
}

proc mark {x col} {
	global ob

	# until bugfix
	return

	set pos [centxy $x -.19 .005]
	set pos [swaps $pos]
	set mark [.c create rect $pos -tag mark -fill $col]
	.c scale $mark 0 0 $ob(scale) -$ob(scale)
}

# create a 1d collapsing slot

proc newslot {cen i randi prevrandi} {
    global ob

    set x1 $ob(prevcen)
    set x2 $cen
    set screenwid [expr {abs($x2 - $x1)}]

    set y1 0.0
    set y2 0.0

    # set ticks [expr {int(400. * 5. / $ob(level))}]
    if {$ob(planar)} {
	set ctl 0
    } elseif {$ob(ankle)} {
	set ctl 8
    } elseif {$ob(linear)} {
	set ctl 16
    }
    switch $ob(drace,dof) {
	wrist_fe {set ctl 7}
	wrist_aa {set ctl 7}
	wrist_ps {set ctl 12}
    }

    if {$ob(domark)} {
	# for debugging, show the initial slot.
	# green is the start point, red is end point.
	# yellow is the center.
	# the final slot is just the red end point.
	.c create line [swaps $x1 -.19 $x2 -.19] -arrow last -fill green3 -width 5 -tag marka
	mark $x1 red
	# mark $mid yellow
	# mark $x2 red
	.c scale marka 0 0 $ob(scale) -$ob(scale)
    }

    if {$ob(wrist)} {
	switch $ob(drace,dof) {
	    "wrist_aa" {
		set nx1 [expr {$x1 * $ob(aa_scale) / 2.}]
		set nx2 [expr {$x2 * $ob(aa_scale) / 2.}]
	    }
	    "wrist_fe" {
		set nx1 [expr {$x1 * $ob(fe_scale) / 2.}]
		set nx2 [expr {$x2 * $ob(fe_scale) / 2.}]
	    }
	    "wrist_ps" {
		set nx1 [expr {$x1 * $ob(ps_scale) / 2.}]
		set nx2 [expr {$x2 * $ob(ps_scale) / 2.}]
	    }
	}
    } elseif {$ob(ankle)} {
	set nx1 [expr {$x1 * $ob(ie_scale) / 2.}]
	set nx2 [expr {$x2 * $ob(ie_scale) / 2.}]
    } elseif {$ob(linear)} {
	set nx1 [expr {$x1 / 2.}]
	set nx2 [expr {$x2 / 2.}]
    } else {
	set nx1 $x1
	set nx2 $x2
    }

    set wid [expr {abs($nx2 - $nx1)}]
    set mid [expr {($nx1 + $nx2) / 2.}]

    if {$ob(savelog)} {
	incr i
	set slotlogfilename [join [list race $ob(whichgame) \
	    $ob(timestamp) ${i} ${prevrandi} ${randi}.dat] _]
	set fn [file join $ob(dirname) $slotlogfilename]
	start_log $fn $ob(logvars)
    }

    set ticks [expr {int(400. * $screenwid / $ob(maxspacing) )}]

    if {$ob(ankle)} {
	set ticks [expr {int($ticks / ($ob(level)/$ob(config,race,speed,slow)))}]
    }

    if {$ob(motorforces)} {
	if {!$ob(ankle)} {
	    movebox 0 $ctl {0 $ticks 1} [swaps $mid $y1 $wid 0.] [swaps $mid $y1 $wid 0.]
	}
	set ob(mbctl) $ctl
	set ob(mbticks) $ticks
	set ob(mbmid) $mid
	set ob(mbwid) $wid
	set ob(mby1) $y1
	set ob(mby2) $y2
	set ob(mbnx2) $nx2
	after 1000 [list movebox 0 $ob(mbctl) {0 $ob(mbticks) 1} \
	    [swaps $ob(mbmid) $ob(mby1) $ob(mbwid) 0.] \
	    [swaps $ob(mbnx2) $ob(mby2) 0. 0.]]
	# puts "movebox 0 $ctl {0 $ticks 1} [swaps $mid $y1 $wid 0.] [swaps $nx2 $y2 0. 0.]"
    }

    set ob(prevcen) $cen
}

# move all the falling stuff every ob(fallms) ms (25)
# deleting the wall we hit keeps us from hitting it again.

proc fall {} {
	global ob mob

	if {!$ob(running)} {
		return
	}

	set level [expr {$ob(level) / 2. * $ob(fallms) / 25.}]
	# move all the falling things $ob(level) pixels
	if {$ob(hdir)} {
		set level [expr {-($level)}]
	}
	eval .c move falling [swaps 0 $level]

	set bbox [.c bbox $ob(racer)]
	set hit [lindex [eval .c find overlapping $bbox] 1]
	if {"$hit" != ""} {
		set tags [.c gettags $hit]
		set lr [lindex $tags 2]
		incr mob($lr)
		set htag [lindex $tags 3]
		.c delete $htag
		hit
	}

	if {$ob(endgame) <= 0 || $ob(gates_deleted) <= $ob(endgame)} {
		after $ob(fallms) fall
	}
}

# delete things with tag i

proc del_thing {i} {
	global mob
	if {[.c find withtag $i] != ""} {
		if {[string index $i 0] == "g"} {
			thrugate
		}
	}
	.c delete $i
}

proc make_racer {} {
	global ob mob

        if {$mob(round)} {
                set shape oval
        } else {
                set shape rectangle
        }

	if {[info exists ob(racer)]} {
		.c delete $ob(racer)
	}

	set ob(racer) [.c create $shape 0 0 .023 .067  -outline "" \
		-fill yellow -tag racer]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc size_racer {} {
	global ob mob

	# distance from screen edge to racer face
	set rdist .015

	# racer dimensions
	set ob(racw) .023
	set ob(racw) .0115
	set ob(racw) [bracket $ob(racw) .005 .1]
	set ob(rach) .067
	set ob(rach) .033
	set ob(racw2) [expr {$ob(racw) / 2.}]

	# racer
	set x1 -$ob(racw2)
	set y1 -.15
	set x2 $ob(racw2)
	set y2 [expr {$y1 + $ob(rach)}]
	eval .c coords racer [swaps $x1 $y1 $x2 $y2]
	.c scale racer 0 0 $ob(scale) -$ob(scale)
}

proc Dialog_Race {string} {
    global drace ob
    set w .drace
    if {[winfo exists $w]} {destroy $w}
    if [Dialog_Create $w $string -borderwidth 10] {

	set ob(drace,rom) random

	if {$ob(ankle)} {
	    label $w.speed_label -text "Speed:"

	    set ob(drace,speed) medium_speed
	    radiobutton $w.b_speed_slow -text [imes "Slow Speed"] \
		-variable ob(drace,speed) -relief flat -value slow_speed
	    radiobutton $w.b_speed_medium -text [imes "Medium Speed"] \
		-variable ob(drace,speed) -relief flat -value medium_speed
	    radiobutton $w.b_speed_fast -text [imes "Fast Speed"] \
		-variable ob(drace,speed) -relief flat -value fast_speed

	    label $w.rom_label -text "Range of Motion:"

	    set ob(drace,rom) medium_rom
	    radiobutton $w.b_rom_short -text [imes "Short ROM"] \
		-variable ob(drace,rom) -relief flat -value short_rom
	    radiobutton $w.b_rom_medium -text [imes "Medium ROM"] \
		-variable ob(drace,rom) -relief flat -value medium_rom
	    radiobutton $w.b_rom_long -text [imes "Long ROM"] \
		-variable ob(drace,rom) -relief flat -value long_rom
	    radiobutton $w.b_rom_random -text [imes "Random"] \
		-variable ob(drace,rom) -relief flat -value random

	    label $w.stiff_label -text "Stiffness:"

	    set ob(drace,stiff) medium_stiff
	    radiobutton $w.b_stiff_low -text [imes "Low Stiffness"] \
		-variable ob(drace,stiff) -relief flat -value low_stiff
	    radiobutton $w.b_stiff_medium -text [imes "Medium Stiffness"] \
		-variable ob(drace,stiff) -relief flat -value medium_stiff
	    radiobutton $w.b_stiff_high -text [imes "High Stiffness"] \
		-variable ob(drace,stiff) -relief flat -value high_stiff

	    label $w.spacer_label -text ""
	}

    if {$ob(planar)} {
	set ob(drace,dof) planar_x
	radiobutton $w.b_planar_x -text [imes "Planar X"] \
	    -variable ob(drace,dof) -relief flat -value planar_x
	radiobutton $w.b_planar_y -text [imes "Planar Y"] \
	    -variable ob(drace,dof) -relief flat -value planar_y
    }
    if {$ob(wrist)} {
	set ob(drace,dof) wrist_ps
	radiobutton $w.b_wrist_ps -text [imes "Wrist Pro/Sup"] \
	    -variable ob(drace,dof) -relief flat -value wrist_ps
	radiobutton $w.b_wrist_aa -text [imes "Wrist Ab/Ad"] \
	    -variable ob(drace,dof) -relief flat -value wrist_aa
	radiobutton $w.b_wrist_fe -text [imes "Wrist Flex/Ext"] \
	    -variable ob(drace,dof) -relief flat -value wrist_fe
    }
    if {$ob(ankle)} {
	set ob(drace,dof) ankle_dp
	label $w.axis_label -text "Axis:"
	radiobutton $w.b_ankle_dp -text [imes "Ankle Dors/Plant"] \
	    -variable ob(drace,dof) -relief flat -value ankle_dp
	radiobutton $w.b_ankle_ie -text [imes "Ankle Inv/Ev"] \
	    -variable ob(drace,dof) -relief flat -value ankle_ie
    }
    if {$ob(linear)} {
	set ob(drace,dof) linear
	radiobutton $w.b_linear -text [imes "Linear"] \
	    -variable ob(drace,dof) -relief flat -value linear
    }

	checkbutton $w.logdata -text [imes "Log Data"] \
	    -variable ob(drace,logdata) -relief flat 
	checkbutton $w.sendforces -text [imes "Send Forces"] \
	    -variable ob(drace,sendforces) -relief flat

	label $w.dummy
	button $w.cancel -text [imes "Cancel"] \
	    -command {set ob(drace,ok) 0}
	button $w.ok -text [imes "Run"] \
	    -command {set ob(drace,ok) 1}

        if {$ob(planar)} {
	grid $w.b_planar_x -sticky w
	grid $w.b_planar_y -sticky w
        }
        if {$ob(wrist)} {
	grid $w.b_wrist_ps -sticky w
	grid $w.b_wrist_aa -sticky w
	grid $w.b_wrist_fe -sticky w
        }
        if {$ob(ankle)} {
	grid $w.axis_label -sticky w
	grid $w.b_ankle_dp -sticky w
	grid $w.b_ankle_ie -sticky w
        }
	if {$ob(ankle)} {
	    grid $w.speed_label -sticky w
	    grid $w.b_speed_slow -sticky w
	    grid $w.b_speed_medium -sticky w
	    grid $w.b_speed_fast -sticky w
	    
	    grid $w.rom_label -sticky w
	    grid $w.b_rom_short -sticky w
	    grid $w.b_rom_medium -sticky w
	    grid $w.b_rom_long -sticky w
	    grid $w.b_rom_random -sticky w
	    
	    grid $w.stiff_label -sticky w
	    grid $w.b_stiff_low -sticky w
	    grid $w.b_stiff_medium -sticky w
	    grid $w.b_stiff_high -sticky w
	    
	    grid $w.spacer_label -sticky w
	}

        if {$ob(linear)} {
	grid $w.b_linear -sticky w
        }
	grid $w.logdata -sticky w
	grid $w.sendforces -sticky w
	grid $w.dummy
	grid $w.cancel $w.ok
    }
    set ob(drace,ok) 0
    Dialog_Wait $w ob(drace,ok) $w.ok
    Dialog_Dismiss $w
    return $ob(drace,ok)
}

proc init_race {} {
    global ob mob env

    set ob(programname) race

    set ob(running) 0

    set ob(endgame) 0

    set ob(whichgame) "def"
    set mob(hdir) 0
    
    # 1 for sound
    set ob(sound) 0

    # no_arm
    # use wrist pro/sup

    set ob(mainbg) black

    # print debug arrow?
    set ob(domark) 1

    set ob(prevrandi) c

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
	set ret [Dialog_Race "Race Setup"]
	if {$ret == 0} {
	    exit
	}
	if {$ob(drace,sendforces)} {
	    set ob(motorforces) 1
	}
	if {$ob(drace,logdata)} {
	    set ob(savelog) 1
	}
	switch $ob(drace,dof) {
	    "planar_x" {
		set mob(hdir) 0
		set ob(whichgame) "plx"
	    } 
	    "planar_y" {
		set mob(hdir) 1
		set ob(whichgame) "ply"
	    } 
	    "wrist_ps" {
		set mob(hdir) 0
		set ob(whichgame) "wps"
	    }
	    "wrist_aa" {
		set mob(hdir) 1
		set ob(whichgame) "waa"
	    }
	    "wrist_fe" {
		set mob(hdir) 0
		set ob(whichgame) "wfe"
	    } 
	    "ankle_ie" {
		set mob(hdir) 0
		set ob(whichgame) "aie"
	    } 
	    "ankle_dp" {
		set mob(hdir) 1
		set ob(whichgame) "adp"
	    } 
	    "linear" {
		set mob(hdir) 1
		set ob(whichgame) "lin"
	    } 
	    default {
		set mob(hdir) 0
		set ob(whichgame) "def"
	    }
	}
    }

    set curtime [clock seconds]
    # planar
    set ob(logfnid) 0
    set ob(logvars) 8
    if {$ob(wrist)} {
	set ob(logfnid) 8
	set ob(logvars) 11
    } elseif {$ob(ankle)} {
	set ob(logfnid) 9
	set ob(logvars) 12
    } elseif {$ob(linear)} {
	set ob(logfnid) 12 
	set ob(logvars) 4
    }

    set ob(logdirbase) $::env(THERAPIST_HOME)

    set ob(patname) [fnstring $env(PATID)]
    set ob(gametype) eval
    set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    set ob(dirname) [file join $ob(logdirbase) $ob(patname) \
	$ob(gametype) $ob(datestamp) ]

    game_log_entry begin

    # the ps range we want is 64 degrees = 1.11 radians
    # the center to center range of the 8 extreme targets is 0.293
    # 1.11 / 0.293 = 3.8
    set ob(ps_scale) 3.8
    set ob(aa_scale) 2.0
    set ob(fe_scale) 2.0
    set ob(dp_scale) 2.0
    # ie -.0147 .. .0147
    set ob(ie_scale) 2.0

    if {$ob(sound)} {
	    package require snack
	    set pop /usr/share/sounds/gnibbles/pop.wav
	    snack::sound pop -file $pop
	    set crash /usr/share/sounds/gnibbles/crash.wav
	    snack::sound crash -file $crash
    }

    set ob(shaking) 0

    set mob(gates_created) 0
    set ob(gates_deleted) 0

    set ob(scale) 1500.0
    set ob(winwidth) .4
    set ob(winheight) .4

    set ob(npos) 8
    # with forces, 320 slots.  with logging, 80 slots.
    if $ob(motorforces) {
	set ob(nsets) 40
    } else {
	set ob(nsets) 10
    }
    set ob(side) .02
    set ob(side2) [expr {$ob(side) * 2.}]

    # centers
    set ob(half,x) [expr {$ob(winwidth) / 2.}]
    set ob(half,y) [expr {$ob(winheight) / 2.}]
    set ob(cx) 0.0
    set ob(cy) 0.0

    set ob(can,x) 600
    set ob(can,y) 600
    set ob(can2,x) [expr {$ob(can,x) / 2.}]
    set ob(can2,y) [expr {$ob(can,y) / 2.}]


    canvas .c -width $ob(can,x) -height $ob(can,y) -bg black
    # for debugging
    .c config -bg gray20

    .c config -highlightthickness 0
    .c config -scrollregion [list -$ob(can2,x) -$ob(can2,y) $ob(can2,x) $ob(can2,y)]

    set ob(bigcan) .c
    catch {grid anchor . center}

    label .status -textvariable ob(status) -font default\
	-background $ob(mainbg) -foreground gray50
	status_mes [imes "Press n key to Start, Alt-m for menu"]

    grid .c
    grid .status

    # wm geometry . 1000x675
    . config -bg black

    set ob(hdir) $mob(hdir)
    set mob(round) 1

    domenu

    make_racer

    size_racer

    bind . <s> stop_race
    bind . <n> new_race
    bind . <q> {done}
    bind . <Escape> {done}
    wm protocol . WM_DELETE_WINDOW { done }


    start_rtl
    wshm no_safety_check 1
    if {$ob(wrist)} {
	wshm wrist_ps_stiff 10.0
	wshm wrist_ps_damp 0.005
	wshm wrist_diff_stiff 20.0
    }
    if {$ob(ankle)} {
	wshm ankle_stiff 75.
	wshm ankle_damp 1.
    }
    if {$ob(linear)} {
	wshm linear_stiff 100.
	wshm linear_damp 1.
    }


    if {$ob(savelog)} {
	wshm logfnid $ob(logfnid)
    }

    do_drag .c

    if {$ob(motorforces)} {

	# when the wrist is paused, it is sending forces to the motors
	# to hold up the handle.  10 min time out to make sure the motors
	# don't overheat.
	if {$ob(wrist)} {
	    after 600000 done
	}
	center_arm
	after 100
    }
    set ob(prevcen) 0.0

    label .disp -textvariable mob(score) -font $ob(scorefont) -bg black -fg yellow
    place .disp -in . -relx 1.0 -rely 0.0 -anchor ne
    do_title
    wm deiconify .
}

proc stop_race {} {
	global mob ob

	set ob(running) 0
	# cancel all afters
	foreach id [after info] {after cancel $id}
	# in case it's red.
	after 500 .c itemconfig racer -fill yellow

	# start this again
	do_drag .c

	.c delete falling
	if {$ob(motorforces)} {
		center_arm
	}
	if {$mob(racrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(racrow)
	}
	# exec beep

	glog "score=$mob(score) dir=$mob(hdir) level=$mob(level) gates=$mob(gates_created) gw=$mob(gatew) left=$mob(left) right=$mob(right)"
	set str "score=$mob(score) dir=$mob(hdir) level=$mob(level) gates=$mob(gates_created) gw=$mob(gatew) left=$mob(left) right=$mob(right)"
	game_log_entry stopgame $str

	status_mes [imes "Press n key to Start, Alt-m for menu"]
}

proc make_fixed_list {n rom} {
    set the_list {}
    switch $rom {
	short_rom {
	    set min 2
	    set max 5
	}
	medium_rom {
	    set min 1
	    set max 6
	}
	long_rom {
	    set min 0
	    set max 7
	}
    }
    foreach j [iota [expr {$n/2}]] {
	lappend the_list $min
	lappend the_list $max
    }
    # puts $the_list
    return $the_list
}

proc new_race {} {
    global ob mob

    # wrist sets 10 min exit timeout
    if {$ob(wrist)} {
	after cancel done
    }

    if {$ob(running)} {
	stop_race
    }
    set ob(running) 1
    
    game_log_entry startgame

    # 4 possible random sequences
    expr {srand(int(rand() * 4))}
    if {$ob(drace,rom) != "random"} {
	set ob(gate_list) [make_fixed_list [expr {$ob(nsets)*$ob(npos)}] $ob(drace,rom)]
	# puts "ob(drace,rom) is $ob(drace,rom)"
    } else {
	set ob(gate_list) [make_rand_list $ob(nsets) $ob(npos)]
    }
# puts $ob(gate_list)
# puts "making list of $ob(nsets) * $ob(npos) slots"

    # scrub args
    regsub -all {[^0-9]} $mob(endgame) {} mob(endgame)
    set ob(endgame) $mob(endgame)
    set ob(endgame) [bracket $ob(endgame) 0 10000]
    
    regsub -all {[^0-9.]} $mob(level) {} mob(level)
    set ob(level) [bracket $mob(level) 1 50]
    
    regsub -all {[^0-9.]} $mob(gatew) {} mob(gatew)
    set ob(gatew) $mob(gatew)
    set ob(gatew) [bracket $ob(gatew) .004 .2]
    
    set ob(maxspacing) [expr {($ob(winwidth) - ($ob(side2) + $ob(gatew)))}]
    set ob(hdir) $mob(hdir)
    
    # changing fallms doesn't work quite right,
    # program needs a bit of tweaking or fixing.
    set ob(fallms) 25
    set ob(fallms) 33
    
    
    if {$ob(ankle)} {
	if [info exists ob(drace,speed)] {
	    switch $ob(drace,speed) {
		slow_speed { 
		    set ob(level) $ob(config,race,speed,slow)
		}
		medium_speed {
		    set ob(level) $ob(config,race,speed,medium)
		}
		fast_speed {
		    set ob(level) $ob(config,race,speed,fast)
		}
	    }
	}
	if [info exists ob(drace,stiff)] {
	    switch $ob(drace,stiff) {
		low_stiff { 
		    wshm ankle_stiff $ob(config,race,stiff,low)
		}
		medium_stiff {
		    wshm ankle_stiff $ob(config,race,stiff,medium)
		}
		high_stiff {
		    wshm ankle_stiff $ob(config,race,stiff,high)
		}
	    }
	}

    } else {
	set ob(level) $mob(level)
    }
    # puts "ob(level) is $ob(level)"
    set ob(newgaterate) [expr {int(20 * 1000. / $ob(level))}]
    set ob(delgaterate) [expr {int(34 * 1000. / $ob(level))}]

    set ob(gates_deleted) 0
    
    array set mob {
	gates_created 0
	score  0
	thru 0
	racrow  0
	maxinrow  0
	left 0
	right 0
	round 1
    }
    
    make_racer
    
    size_racer
    
    if {!$ob(motorforces)} {
	# stiffen unused wrist dof
	switch $ob(drace,dof) {
	    wrist_fe {
		wshm wrist_diff_damp 0.0
		movebox 0 7 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	    }
	    wrist_aa {
		wshm wrist_diff_damp 0.0
		movebox 0 7 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	    }
	    wrist_ps {
		wshm wrist_ps_damp 0.0
		movebox 0 12 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	    }
	}
    }
    do_gate
    fall

    status_mes [imes "Press Alt-m for menu"]
}

proc do_drag {w} {
	global ob

	# hdir == 0 means the walls fall from the top
	# hdir == 1 means the walls "fall" from the right
	set x 0.0
	set y 0.0
	if {$ob(hdir) == 0} {
	    set x [getptr x]
	    switch $ob(drace,dof) {
		wrist_ps { set x [rshm wrist_ps_pos]
		    # scale pro/sup down
		    set x [expr $x / $ob(y_scale)]
		}
	    }
	    if {$ob(wrist)} {
		foreach {x y} [wrist_ptr_scale $x $y] break
	    } elseif {$ob(ankle)} {
		foreach {x y} [ankle_ptr_scale $x $y] break
	    } elseif {$ob(linear)} {
		foreach {x y} [linear_ptr_scale $x $y] break
	    }
	    dragx $w $x racer
	} else {
	    set y [getptr y]
	    if {$ob(drace,dof) == "wrist_aa"} {
		set y [rshm wrist_aa_pos]
		foreach {x y} [wrist_ptr_scale $x $y] break
	    } elseif {$ob(ankle)} {
		foreach {x y} [ankle_ptr_scale $x $y] break
	    } elseif {$ob(linear)} {
		foreach {x y} [linear_ptr_scale $x $y] break
	    }
	    dragy $w $y racer
	}

	if {$ob(endgame) <= 0 || $ob(gates_deleted) <= $ob(endgame)} {
		after 8 do_drag .c
	}
}

proc dragx {w x what} {
	global ob

	set x1 [bracket $x -$ob(half,x) $ob(half,x)]
	set x1 [expr {$x1 - $ob(racw2)}]
	set x2 [expr {$x1 + $ob(racw)}]
	# foreach {d1 y1 d2 y2} [.c coords $what] {break}
	set y1 -.15
	set y2 [expr {$y1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

proc dragy {w y what} {
	global ob

	set y1 [bracket $y -$ob(half,y) $ob(half,y)]
	set y1 [expr {$y1 - $ob(racw2)}]
	set y2 [expr {$y1 + $ob(racw)}]
	# foreach {d1 x1 d2 x2} [.c coords $what] {break}
	set x1 -.15
	set x2 [expr {$x1 + $ob(rach)}]
        .c coords $what $x1 $y1 $x2 $y2
	.c scale $what 0 0 $ob(scale) -$ob(scale)
}

proc hit {} {
	global ob mob
	if {$ob(sound)} {
		crash play
	}
	
	.c itemconfig racer -fill red
	after 500 .c itemconfig racer -fill yellow

	incr mob(score) -10
	incr ob(gates_deleted)
	if {$mob(racrow) > $mob(maxinrow)} {
		set mob(maxinrow) $mob(racrow)
	}
	set mob(racrow) 0
	do_title
	if {$ob(gates_deleted) == $mob(endgame)} {
		stop_race
	}
}

# this gate was passed rather than hit.

proc thrugate {} {
	global ob mob
	if {$ob(sound)} {
		pop play
	}

	incr mob(thru)
	incr mob(score) 10
	incr mob(racrow)
	incr ob(gates_deleted)
	do_title
	if {$ob(gates_deleted) == $mob(endgame)} {
		stop_race
	}
}

proc domenu {} {
	global ob mob
	set m [menu_init .menu]
	menu_v $m endgame "Game Length" [expr {$ob(nsets) * $ob(npos)}]
	menu_v $m gatew "Gate Width" .067
	menu_v $m level "Level (1-50)" 5
	menu_t $m b0 "" ""

	menu_cb $m hdir "Horiz Motion"
	menu_cb $m round "Oval Racer"
	menu_t $m b1 "" ""

	menu_t $m gates_created "Total Gates"
	menu_t $m thru "Through Gates"
	menu_t $m left "Hit Left"
	menu_t $m right "Hit Right"
	menu_t $m b2 "" ""
	menu_t $m score Score
	menu_t $m racrow "Current Streak"
	menu_t $m maxinrow "Longest Streak"
	menu_t $m b3 "" ""

	menu_b $m newgame "New Game (n)" new_race
	menu_t $m hide "Toggle Menu (Alt-m)" ""
	menu_b $m stopgame "Stop Game (s)" stop_race
	menu_b $m quit "Exit (q)" {done}
}

proc done {} {
        global ob
	stop_race
	stop_log
	if {$ob(wrist)} {
		wdone
	}
        game_log_entry end [current_robot]

	stop_rtl
	exit
}

init_race

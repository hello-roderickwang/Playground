# tcl i/o with shm (user mode shared memory buffer) program
# sourced by other tcl scripts

# InMotion2 robot system software

# Copyright 2003-2013 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

proc every {ms body {id ::after_id}} {
    eval $body
    set $id [after $ms [info level 0]]
}

proc procname {} {
    return [lindex [info level -1] 0]
}

proc cancel_afters {} {
    foreach id [after info] {
        after cancel $id
    }
}

# reap zombie processes after "exec &" commands exit
# see: http://mini.net/tcl/1039
proc reap_zombies {} {
    catch {exec ""}
}

# print a string, with a difference in ms since the last dtime
proc dtime {str} {
     global ob
     if {![info exists ob(dtimetime)]} {
         set ob(dtimetime) [clock clicks -mill]
     }
     set time [clock clicks -mill]
     set dtime [expr {$time - $ob(dtimetime)}]
     puts "dtime: $dtime - $str"
     set ob(dtimetime) $time
}

# flush typeahead
proc flushin {{fdin stdin}} {
    fconfigure stdin -blocking 0
    read stdin
    fconfigure stdin -blocking 1
}

# flip y coordinate

proc y_up {args} {
    set ret ""
    if {[llength $args]==1} {
        set args [lindex $args 0]
    }
    foreach {x y} $args {
        lappend ret $x [expr {-$y}]
    }
    return $ret
}

# given a center position and radius, like 100 100 10,
# centxy returns x1 y1 x2 y2, like 90 90 110 110.

proc centxy {x y rad} {
    set x1 [expr {$x - $rad}]
    set y1 [expr {$y - $rad}]
    set x2 [expr {$x + $rad}]
    set y2 [expr {$y + $rad}]
    list $x1 $y1 $x2 $y2
}

proc centertag {w tag} {
    foreach {x1 y1 x2 y2} [$w coords $tag] { break }
    set x [expr {$x1 + $x2 / 2.}]
    set y [expr {$y1 + $y2 / 2.}]
    list $x $y
}

# given a src and dest point in {x y w h} form, convert the source point
# to a slot that starts at src, ends at dest, and morphs to dest.
# returns a new src.
# e.g. to move in X from -.03 to .05,
# the new src center point would be .01, with a width of .08.
# for .05 to -.03 it would be the same.

proc point_to_collapse {src dest} {
    foreach {srcx srcy srcw srch} $src { break }
    foreach {destx desty destw desth} $dest { break }
    set x [expr {$srcx +(($destx - $srcx) / 2.)}]
    set y [expr {$srcy +(($desty - $srcy) / 2.)}]
    set w [expr {abs($destx - $srcx)}]
    set h [expr {abs($desty - $srcy)}]
    return [list $x $y $w $h]
}

# lkm loaded?

proc is_lkm_loaded {} {
    # file exists /proc/pwrdaq
    # file exists /proc/xenomai/registry/native/pipes/crob_out
    expr {![catch {exec pgrep -x robot}]}
}

proc is_Tk_loaded {} {
    expr {![catch {package present Tk}]}
}

proc no_kbd_repeat {} {
    # turn off space bar repeat in X Windows
    exec /usr/bin/xset -r 65
}

# load lkms

proc start_lkm {} {
    global ob
    if {![file executable $::env(CROB_HOME)/go]} {
        error "start_lkm: could not run go"
    }

    # puts "calling exec go"
    set status [catch {exec $::env(CROB_HOME)/go} result]
    if {$result != ""} {
        puts "go: $result"
    }
    # puts "start_lkm status $status"   ;# TODO: delete me
    # puts "the status is $status, errorCode is $::errorCode"
    if {$status != 0 && $::errorCode != "NONE"} {
        catch {stop_lkm} stop_result
	error "start_lkm: could not start robot\n\
	result string:\n<<\n$result\n>>\n"
    }

}

# unload lkms

proc stop_lkm {} {
    global ob

    # turn keyboard autorepeat in X windows back on
    exec /usr/bin/xset r on
    # turn space bar repeat back on
    exec /usr/bin/xset r 65

    if {![file executable $::env(CROB_HOME)/stop]} {
        puts "stop_lkm: could not run stop"
        exit 1
    }

    set status [catch {exec $::env(CROB_HOME)/stop} result]
    if {$status != 0} {
        puts "stop_lkm: could not stop robot process"
        puts "result string:\n<<\n$result\n>>\n"
    }
}

# start shm - the shared memory buffer C program

proc start_shm {} {
    global ob
    if {! [file exists $::env(CROB_HOME)/shm] } {
	puts stderr "start_shm: can't find shared memory program $::env(CROB_HOME)/shm"
        exit 1
    }
    set ob(shm) [open "|$::env(CROB_HOME)/shm" r+]
    fconfigure $ob(shm) -buffering line
    after 100
    set check [rshm last_shm_val]
    if {$check != 12345678} {
        puts "start_shm: bad shm check value."
        puts "make sure all software has been compiled with latest cmdlist.tcl"
        exit 1
    }
}

proc stop_shm {} {
    global ob
    if {![info exists ob(shm)]} {
        return
    }
    thermal_write_file thermal
    set ob(loaded) 0
    puts $ob(shm) "q"
    close $ob(shm)
    unset ob(shm)
}

set ob(last_start_log_time) 0

proc start_log {logfile {num 3} {uheaderfile ""}} {
    global ob

    # puts "start_log $logfile $num"
    wshm nlog $num
    if {[rshm asciilog]} {
	set logver 2.0
    } else {
	set logver 1.0
    }

    # make sure the dir is there
    file mkdir [file dirname $logfile]

    # is it already there?  if so, overwrite, but warn.
    if {[file exists $logfile]} {
        puts stderr "Warning: start_log overwriting $logfile."
    }

    # write log header
    logheader $logfile $logver $num $uheaderfile

    set ob(savedatpid) [exec cat < /proc/xenomai/registry/native/pipes/crob_out >> $logfile &]
    set ob(last_start_log_time) [clock clicks -milliseconds]
}

proc stop_log {} {
    global ob

    # puts "stop_log"
    wshm nlog 0
    if {[info exists ob(savedatpid)]} {
        exec kill $ob(savedatpid)
        unset ob(savedatpid)
    }
}

proc xyplot_log {filename} {
    global ob
    exec [file join $::env(CROB_HOME) xygp] $filename &
}

proc plot_log {filename {plotcmd {}}} {
    global ob
    exec [file join $::env(CROB_HOME) gp] $filename $plotcmd &
}

# if the shm process gets killed from outside, the puts here will fail.
# this will set shm_puts_exit_in_progress, and cleanup should happen.
# don't call stop_shm or stop_loop, since these just do more i/o to the
# now broken shm channel.

proc shm_puts {str} {
    global ob
    if {[info exists ob(shm_puts_exit_in_progress)]} {
        puts stderr "shm_puts error, exit in progress..."
    }
    if {[catch {puts $ob(shm) $str}]} {
        set ob(shm_puts_exit_in_progress) 1
        puts stderr "shm_puts error, stopping lkm."
        stop_lkm
        exit 1
    }
}

# i is array index in both.

# wshm writes systcl vars
# like /sbin/sysctl -w where=what

proc wshm {where what {i 0}} {
    global ob
    if {![info exists ob(shm)]} {
        return
    }
    if {[info exists ob(shm_puts_exit_in_progress)]} {
        return
    }
    shm_puts "s $where $i $what"

    gets $ob(shm) istr
    set what [lindex $istr 0]
    if {[string equal $what "?"]} {
        puts stderr $istr
    }
}

# rshm reads systcl vars
# like /sbin/sysctl where

proc rshm {where {i 0}} {
    global ob
    set what "???"
    set ob(last_rshm_failed) "yes"
    if {![info exists ob(shm)]} {
        return "0.0"
    }
    if {[info exists ob(shm_puts_exit_in_progress)]} {
        return "0.0"
    }
    shm_puts "g $where $i"

    gets $ob(shm) istr
    set what [lindex $istr 0]
    set ob(last_rshm_failed) "no"
    if {[string equal $what "?"]} {
        set ob(last_rshm_failed) "yes"
        puts stderr $istr
        return "0.0"
    }
    set what [lindex $istr 3]
    return $what
}

proc start_loop {} {
    wshm paused 0
    wshm slot_max 4
    thermal_read_file thermal
}

# this pauses the main loop if you want to restart it.
# sensors are read.  actuators are not written.
proc pause_loop {} {
    wshm paused 1
}

# this stops the main loop and must be called before stop_lkm
# paused is set first to zero motor command voltages
# to receive and process the commands.  (100 ms is 20 ticks at 200 Hz.)

proc stop_loop {} {
    wshm paused 1
    after 100
}

proc mouse_getptr {p} {
    expr {[winfo pointer$p $::tachw]}
}

# robot ptr/vel

proc getptr {p} {
    rshm $p
}

set ob(planar) 0
proc use_planar {} {
    global ob
    set ob(planar) 1
}

set ob(planarwrist) 0
proc use_planarwrist {} {
    global ob
    set ob(planarwrist) 1
}

set ob(planarhand) 0
proc use_planarhand {} {
    global ob
    set ob(planarhand) 1
}

# same as planarhand, for now.
proc use_hand {} {
    global ob
    set ob(planarhand) 1
}

set ob(wrist) 0
# redeclare getptr for wrist robot
proc use_wrist {} {
    global ob

    set ob(wrist) 1
    proc getptr {p} {
        global ob
        set ret 0.0
        if {$p == "x"} {
            set ret [rshm wrist_fe_pos]
        }
        if {$p == "y"} {
            set ret [rshm wrist_aa_pos]
        }
        return $ret
    }

    # difference between meters on planar and degrees on wrist
    set ob(wrist_scale) [expr {14. / 26.}]
    # in race game,
    # the ps range we want is 64 degrees = 1.11 radians
    # the center to center range of the 8 extreme targets is 0.293
    # 1.11 / 0.293 = 3.788...
    set ob(wrist_ps_scale) [expr {1.11 / 0.293}]
    # difference between ab/ad and flex/ext
    set ob(y_scale) 2.0

    proc wrist_ptr_scale {x y} {
        global ob
        set retx [expr {$x * $ob(wrist_scale)}]
        set rety [expr {$ob(y_scale) * $y * $ob(wrist_scale)}]
        # set rety [expr {$y * $ob(wrist_scale)}]
        return [list $retx $rety]
    }

    # send arm from current position to center, at constant speed
    proc center_arm {{cx 0.0} {cy 0.0}} {
        set x [getptr x]
        set y [getptr y]

	foreach {x y} [wrist_ptr_scale $x $y] break

        # set dist [edist $x $y $cx $cy]
        # set ticks [expr {int($dist * 4000.)}]
        # movebox 0 7 {0 $ticks 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}
        # for wrist, use constant 1 sec
        movebox 0 7 {0 200 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}

    }
}


set ob(ankle) 0
# redeclare getptr for ankle robot
proc use_ankle {} {
    global ob

    set ob(ankle) 1
    proc getptr {p} {
        global ob
        set ret 0.0
        if {$p == "x"} {
            set ret [rshm ankle_ie_pos]
        }
        if {$p == "y"} {
            set ret [rshm ankle_dp_pos]
        }
        return $ret
    }

    # difference between meters on planar and ankle
    set ob(ankle_scale) 1.0
    # difference between dp and ie
    set ob(y_scale) 1.0

    proc ankle_ptr_scale {x y} {
        global ob
        set retx [expr {$x * $ob(ankle_scale)}]
        set rety [expr {$ob(y_scale) * $y * $ob(ankle_scale)}]
        # set rety [expr {$y * $ob(ankle_scale)}]
        return [list $retx $rety]
    }

    # send arm from current position to center, at constant speed
    proc center_arm {{cx 0.0} {cy 0.0}} {
        set x [getptr x]
        set y [getptr y]

	foreach {x y} [ankle_ptr_scale $x $y] break

        movebox 0 8 {0 200 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}

    }
}

set ob(linear) 0
# redeclare getptr for linear robot
proc use_linear {} {
    global ob

    set ob(linear) 1
    proc getptr {p} {
        global ob
        set ret 0.0
        set ret [rshm linear_pos]
        return $ret
    }

    # difference between meters on planar and linear
    set ob(linear_scale) 1.0
    # difference between x and y
    set ob(y_scale) 1.0

    proc linear_ptr_scale {{x 0} {y 0}} {
        global ob
        set retx [expr {$x * $ob(linear_scale)}]
        return [list $retx $retx]
    }

    # send arm from current position to center, at constant speed
    proc center_arm {{cx 0.0} {cy 0.0}} {
        set x [getptr x]
        set y $x

	foreach {x y} [linear_ptr_scale $x $y] break

        movebox 0 16 {0 200 1} {$x 0.0 0.0 0.0} {$cx 0.0 0.0 0.0}
    }
}


proc soft_getvel {p} {
    rshm soft_${p}vel
}

proc fsoft_getvel {p} {
    rshm fsoft_${p}vel
}

proc tach_getvel {p} {
    rshm tach_${p}vel
}

proc getvel {p} {
    rshm ${p}vel
}

proc gettrq {p} {
    rshm ${p}_torque
}

proc getvolts {p} {
    rshm ${p}_volts
}

proc getfrc {p} {
    rshm ${p}_force
}

proc getftfrc {p} {
    rshm ft_${p}dev
}

proc getwftfrc {p} {
    rshm ft_${p}world
}

# checkerror should be called from inside a user-mode program event loop,
# to make sure that the event loop isn't generating too many errors or
# warnings.  a few such errors are expected in normal operation, but if
# something goes wrong, they should happen on every sample and they will
# exceed the max (10, for example) quickly.

proc checkerror {{max 10}} {
    global ob
    set ob(errormax) $max
    set nerrors [rshm nerrors]
    if {$nerrors > $ob(errormax)} {
        set i [rshm errorindex]
        set ei $i
        set error0i [rshm errori $i]
        set error0code [rshm errorcode $i]
        incr i -1
        set error1i [rshm errori $i]
        set error1code [rshm errorcode $i]
        incr i -1
        set error2i [rshm errori $i]
        set error2code [rshm errorcode $i]

	set estring "InMotion2 System, Pausing control loop.\n\
nerrors = $nerrors,\n\
last ($ei): iteration = $error0i, code = $error0code.\n\
last-1: iteration = $error1i, code = $error1code.\n\
last-2: iteration = $error2i, code = $error2code.\n\
You may run shm to analyze system state, then run ./stop ."
        stop_loop
        error $estring
        # stop_lkm
        # after 2000
        # exit 1
    }
}

# checkfault should be called from inside a user-mode program event loop,
# to make sure that the event loop isn't generating faults.

proc checkfault {} {
    global ob
    set fault [rshm fault]
    if {$fault == 0} return
    # else we have a fault

    stop_log

    set nerrors [rshm nerrors]
    set i [rshm errorindex]
    set ei $i
    set errori [rshm errori $i]
    set errorcode [rshm errorcode $i]

    switch $errorcode {
    9	{ set estring "Ankle robot shaft hit stops"}
    10	{ set estring "Ankle robot left shaft slipped,\nstop robot, call IMT"}
    11	{ set estring "Ankle robot right shaft slipped,\nstop robot, call IMT"}
    default	{ set estring "Robot fault code $errorcode"}
    }
    set fstring "InMotion2 System, detected hardware fault.\n\
fault = $fault,\n\
    iteration = $errori, code = $errorcode.\n\
    $estring\n\
    Please exit from the game.\n"
    error $fstring
}

proc pl_checkranges {{pos {0.0 0.0}} {velmag 0.0} {ftmag 0.0}} {

    foreach {x y} $pos break
    # (-0.9 .. 0.9) is the x range.
    if {abs($x) > 0.9} {puts "abs(x) > .9 $x"}
    # (-0.25 .. 1.15) is the y range.
    if {abs($y - 0.45) > 0.7} {puts "abs(y - 0.45) > 0.7 $y"}

    if {$velmag > 3.0} {puts "velmag > 3.0 $velmag"}
    if {$ftmag > 120.0} {puts "ftmag > 1 $ftmag"}
}

# note: you may have more than one movebox active at a time, but it takes a
# full sample period for the movebox to take effect, never do two moveboxes
# in a row without a wait of at least 10ms in between.


# movebox to move a box
#		i f  forlist    from                  to
# e.g.: movebox 0 0 {0 1000 1} {0.0 0.0 0.005 0.005} {0.15 0.15 0.005 0.005}

proc movebox {slot_id slot_fnid forlist box0 box1} {
    global ob

    # the uplevel/subst allows users to put $vars in the lists.
    set forlist [uplevel 1 [list subst -nocommands $forlist]]
    set box0 [uplevel 1 [list subst -nocommands $box0]]
    set box1 [uplevel 1 [list subst -nocommands $box1]]

    # dtime "movebox $slot_id $slot_fnid $forlist $box0 $box1"
    movebox2 $slot_id $slot_fnid $forlist $box0 $box1
}

proc movebox2 {slot_id slot_fnid forlist box0 box1} {
    global ob

    set tslot_go [rshm slot_go]
    if {$tslot_go} {
        # reschedule myself in 10 ms
        # dtime "movebox2, rescheduling..."
        # dtime "movebox: resched"
        after 10 [info level 0]
        return
    }
    # dtime "movebox2 $slot_id   $slot_fnid   $forlist   $box0   $box1"

    set slot_b0_x 0.0
    set slot_b0_y 0.0
    set slot_b0_w 0.0
    set slot_b0_h 0.0
    set slot_b1_x 0.0
    set slot_b1_y 0.0
    set slot_b1_w 0.0
    set slot_b1_h 0.0
    foreach {slot_i slot_term slot_incr} $forlist break
    foreach {slot_b0_x slot_b0_y slot_b0_w slot_b0_h} $box0 break
    foreach {slot_b1_x slot_b1_y slot_b1_w slot_b1_h} $box1 break

    set dev_scale 1.0
    if {$ob(wrist)} {
        set dev_scale $ob(wrist_scale)
    } elseif {$ob(ankle)} {
        set dev_scale $ob(ankle_scale)
    }
    # this scaling stuff probably needs to be more general
    if {[info exists ob(y_scale)]} {
        # divide all variables by scale
        # divide y variables by y_scale
        set slot_b0_x [expr {$slot_b0_x / $dev_scale}]
        set slot_b1_x [expr {$slot_b1_x / $dev_scale}]
        set slot_b0_w [expr {$slot_b0_w / $dev_scale}]
        set slot_b1_w [expr {$slot_b1_w / $dev_scale}]

	set slot_b0_y [expr {$slot_b0_y / ($ob(y_scale) * $dev_scale)}]
	set slot_b1_y [expr {$slot_b1_y / ($ob(y_scale) * $dev_scale)}]
	set slot_b0_h [expr {$slot_b0_h / ($ob(y_scale) * $dev_scale)}]
	set slot_b1_h [expr {$slot_b1_h / ($ob(y_scale) * $dev_scale)}]
    }

    foreach i {
	slot_id slot_fnid
	slot_i slot_term slot_incr
	slot_b0_x slot_b0_y slot_b0_w slot_b0_h
	slot_b1_x slot_b1_y slot_b1_w slot_b1_h
    } {wshm $i [set $i]}

    wshm slot_running 1
    wshm slot_go 1
    # wshm slot_max 1
}

# stop a slot currently in progress

proc stop_movebox {{slot_id 0}} {
    set tslot_go [rshm slot_go]
    if {$tslot_go} {
        # reschedule myself in 10 ms
        # puts "stop_movebox, rescheduling..."
        # dtime "stop_movebox: resched"
        after 10 [info level 0]
        return
    }

    foreach i {
	slot_fnid
	slot_i slot_term slot_incr
	slot_b0_x slot_b0_y slot_b0_w slot_b0_h
	slot_b1_x slot_b1_y slot_b1_w slot_b1_h
	slot_running
    } {wshm $i 0}
    wshm slot_id $slot_id
    wshm slot_go 1
}

proc star_once {} {
    global star

    if {[info exists star(i)]} {
        return
    }

    set star(i) 0

    set star(hw) 0.005
    set star(c) [list 0.0 0.0 $star(hw) $star(hw)]
    set star(s) [list 0.0 -0.14 $star(hw) $star(hw)]
    set star(n) [list 0.0 0.14 $star(hw) $star(hw)]
    set star(w) [list -0.14 0.0 $star(hw) $star(hw)]
    set star(e) [list 0.14 0.0 $star(hw) $star(hw)]
    set star(nw) [list -0.14 0.14 $star(hw) $star(hw)]
    set star(ne) [list 0.14 0.14 $star(hw) $star(hw)]
    set star(sw) [list -0.14 -0.14 $star(hw) $star(hw)]
    set star(se) [list 0.14 -0.14 $star(hw) $star(hw)]
    set star(dirs) {n ne e se s sw w nw}
}

star_once

proc start_star {{sec 5}} {
    global star

    set star(trips) 0
    # takes 1 second
    center_arm
    # after 2 seconds
    lappend star(afters) [after 2000 star_proc $sec]
}

proc star_proc {{sec 5}} {
    #         x     y
    global star ob

    if {!$ob(running)} {
        return
    }
    incr star(trips)
    # puts "round trips: $star(trips)"
    set star(sec) $sec
    # after msec
    set star(atime) [expr {int($sec * 1000)}]
    set star(atime2) [expr {int(2 * $sec * 1000)}]
    # samples Hz

    set star(dir) [lindex $star(dirs) $star(i)]

    # stime is secs * sample time in Hz
    set star(stime) [expr {int($sec * .9 * 200)}]

    movebox 0 0 {0 $star(stime) 1} $star(c) $star($star(dir))

    set star(afters) [after $star(atime) {movebox 0 0 {0 $star(stime) 1} $star($star(dir)) $star(c)}]

    lappend star(afters) [after $star(atime2) star_proc $star(sec)]

    set star(i) [expr {($star(i) + 1) % 8}]
}

proc star_stop {} {
    global star ob

    if {![info exists star(afters)]} {
        return
    }
    foreach i $star(afters) {
        after cancel $i
    }
}

# calculate Euclidean distance.  (Why not Pythagorean?)
proc edist {x1 y1 x2 y2} {
    expr {hypot($x1 - $x2, $y1 - $y2)}
}

# turn off the planar .2 meter safety position box for 2 seconds,
# so that the center_arm can pull the arm to the center from outside
# the safety zone if needs be.

proc no_safety_pos {ms} {
    global ob
    set ob(saved_pl_safety_pos) [rshm safety_pos]
    wshm safety_pos 2.0
    after $ms {wshm safety_pos $::ob(saved_pl_safety_pos)}
}

# send arm from current position to center, at constant speed
proc center_arm {{cx 0.0} {cy 0.0}} {
    set x [getptr x]
    set y [getptr y]

    set dist [edist $x $y $cx $cy]
    set ticks [expr {int($dist * 2000.)}]
    set ms [expr {$ticks * 5}]
    no_safety_pos $ms
    movebox 0 0 {0 $ticks 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}
}

# send arm from current position to center, taking two seconds.
proc center_arm_2s {{cx 0.0} {cy 0.0}} {
    set x [getptr x]
    set y [getptr y]

    set ticks [expr {2 * [rshm Hz]}]
    set dist [edist $x $y $cx $cy]
    movebox 0 0 {0 $ticks 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}
}

# send arm from current position to center, taking one second.
proc center_arm_1s {{cx 0.0} {cy 0.0}} {
    set x [getptr x]
    set y [getptr y]

    set ticks [rshm Hz]
    set dist [edist $x $y $cx $cy]
    movebox 0 0 {0 $ticks 1} {$x $y 0.0 0.0} {$cx $cy 0.0 0.0}
}

proc popup_mes {str} {
    toplevel .popup_mes
    label .popup_mes.lab
    pack .popup_mes.lab
    wm title .popup_mes "Message"

    .popup_mes.lab config -text $str -font "Times 18" -padx 20 -pady 40
    set x [winfo rootx .]
    set y [winfo rooty .]
    incr x 400
    incr y 300
    wm geometry .popup_mes +${x}+${y}
    wm deiconify .popup_mes
    raise .popup_mes
}

proc del_popup_mes {} {
    destroy .popup_mes
}

# center wrist
proc wcenter {{x 0.0} {y 0.0}} {
    # safety margin for movebox resched
    after 20
    set curx [rshm wrist_fe_pos]
    set cury [rshm wrist_aa_pos]
    set curps [rshm wrist_ps_pos]
    foreach {curx cury} [wrist_ptr_scale $curx $cury] break
    wshm wrist_nocenter3d 1
    # wrist
    movebox 0 7 {0 400 1} {$curx $cury 0.0 0.0} {$x $y 0.0 0.0}
    # wrist_ps
    set pssrc [point_to_collapse [list $curps 0.0 0.0 0.0] {0.0 0.0 0.0 0.0}]
    movebox 1 21 {0 400 1} $pssrc {0.0 0.0 0.0 0.0}
    after 2000 {set ::vwvar 1}
    vwait ::vwvar
}

# center and lower wrist
proc wdone {} {
    set pss [rshm wrist_ps_stiff]
    # gentle ps
    wshm wrist_ps_stiff [expr {$pss / 4.0}]
    if {[is_Tk_loaded]} {
        popup_mes "Parking wrist robot."
        after 4000 del_popup_mes
    } else {
        puts "Parking wrist robot."
    }
    wcenter
    set curx [rshm wrist_fe_pos]
    set cury [rshm wrist_aa_pos]
    foreach {curx cury} [wrist_ptr_scale $curx $cury] break
    movebox 0 7 {0 400 1} {$curx $cury 0.0 0.0} {0.0 -1.0 0.0 0.0}
    after 2000 {set ::vwvar 1}
    vwait ::vwvar
}

# center ankle
proc acenter {{x 0.0} {y 0.0}} {
    set curx [rshm ankle_ie_pos]
    set cury [rshm ankle_dp_pos]
    # ankle_point
    movebox 0 8 {0 400 1} {$curx $cury 0.0 0.0} {$x $y 0.0 0.0}
    after 2000 {set ::vwvar 1}
    vwait ::vwvar
}

# center and lower wrist
proc adone {} {
    acenter
}

# absolute kick, assuming no other slots are active.
# does not add kick to an existing slot.

set ob(kd) .05
proc kick {{dir down}} {
    global ob
    set x [getptr x]
    set y [getptr y]
    set x2 $x
    set y2 $y

    switch $dir {
        west -
        left {
                set x2 [expr {$x - $ob(kd)}]
            }

        east -
        right {
                set x2 [expr {$x + $ob(kd)}]
            }

        south -
        down {
                set y2 [expr {$y - $ob(kd)}]
            }

        north -
        up {
                set y2 [expr {$y + $ob(kd)}]
            }

	default  { return }

    }


    set ctl 0
    if {$ob(wrist)} {
        set ctl 7
    } elseif {$ob(ankle)} {
        set ctl 8
    }

    # kick for 1/20 sec, then stop all slots.
    # for wrist
    movebox 0 $ctl {0 10 1} {$x $y 0.0 0.0} {$x2 $y2 0.0 0.0}
    after 50 {stop_movebox 0}
}

proc personality {} {
    return [ exec cat /opt/imt/personality ]
}

proc personality_is {p} {
    return [ string equal $p [ personality ] ]
}


# bias the ft
proc ft_bias {} {
    set have_ft [file exists $::env(IMT_CONFIG)/have_atinetft]
    if { [personality_is ce] } {
	wshm ft_dobias 1
    } elseif { [personality_is g2] && $have_ft } {
	exec curl -s http://atinetft/rundata.cgi?cmd=bias
    }
}

proc ft_unbias {} {
    set have_ft [file exists $::env(IMT_CONFIG)/have_atinetft]
    if { [personality_is g2] && $have_ft } {
        exec curl -s http://atinetft/setting.cgi?setbias0=0&setbias1=0&setbias2=0&setbias3=0&setbias4=0&setbias5=0
    }
}

# shortcuts for start/stop

proc start_rtl {} {
    start_lkm
    start_shm
    start_loop
    after 100
}

proc stop_rtl {} {
    stop_loop
    after 100
    stop_shm
    stop_lkm
}

# if there is no arm and you want to use the mouse as a pointer

proc no_arm {} {
    global ob
    # pixel offset between 0 and center, same here for x/y
    # this is a kludge, but close enough.

    set ob(ptroffset) 0

    # make all these do nothing
    proc start_lkm {} { }
    proc start_shm {} { }
    proc start_loop {} { }
    proc stop_lkm {} { }
    proc stop_shm {} { }
    proc stop_loop {} { }
    proc rshm {where {i 0}} { }
    proc wshm {where what {i 0}} { }

    proc start_log {logfile {num 3} {uheaderfile none}} {
        # make sure the dir is there
        file mkdir [file dirname $logfile]

	if {[rshm asciilog]} {
	    set logver 2.0
	} else {
	    set logver 1.0
	}

        # write log header
        logheader $logfile $logver $num
    }

    proc stop_log {} { }

    # make getptr read the mouse, and hack it into a screen positon.

    proc getptr {p} {
        global ob
        set w $ob(bigcan)
        set val [expr {[winfo pointer$p $w] - [winfo root$p $w]}]
        # flip y
        if {$p == "x"} {
            set val [expr {$val - $ob(half,x)}]
        } else {
            set val [expr {$val - $ob(half,y)}]
            set val [expr {-$val}]
        }
        if {$ob(linear)} {
            # ... no xform for linear?
        }
        # scale world to screen
        expr {$val / $ob(scale)}
    }

}

# write a log file header.
# pad with commented dots to 4096 bytes of ascii stuff
# (or truncate)
# make sure this is ascii, multi-byte chars will be messy here.

proc logheader {filename logver ncols {headerfile ""}} {
    global ob
    exec $::env(CROB_HOME)/loghead $filename $logver $ncols $headerfile
}


# exec with event loop, for tk.
# for long running progs, like go/stop
# http://mini.net/tcl/3039

# not using it right now, because it doesn't seem to handle
# error return from exec'd program correctly

proc tk_exec_fileevent {id} {
    global tkex

    if {[eof $tkex(pipe,$id)]} {
        fileevent $tkex(pipe,$id) readable ""
        set tkex(cond,$id) 1
        return
    }

    append tkex(data,$id) [read $tkex(pipe,$id) 1024]
}

proc tk_exec {args} {
    global tkex
    global tcl_platform
    global env

    if {![info exists tkex(id)]} {
        set tkex(id) 0
    } else {
        incr tkex(id)
    }

    set id $tkex(id)

    set keepnewline 0

    for {set i 0} {$i < [llength $args]} {incr i} {
        set arg [lindex $args $i]
        switch -glob -- $arg {
            -keepnewline {
                    set keepnewline 1
                }
            -- {
                    incr i
                    break
                }
            -* {
                    error "unknown option: $arg"
                }
            ?* {
                    # the glob should be on *, but the wiki reformats
                    # that as a bullet
                    break
                }
        }
    }

    if {$i > 0} {
        set args [lrange $args $i end]
    }

    if {$tcl_platform(platform) == "windows" && [info exists env(COMSPEC)]} {
        set args [linsert $args 0 $env(COMSPEC) "/c"]
    }

    set pipe [open "|$args" r]

    set tkex(pipe,$id) $pipe
    set tkex(data,$id) ""
    set tkex(cond,$id) 0

    fconfigure $pipe -blocking 0
    fileevent $pipe readable "tk_exec_fileevent $id"

    vwait tkex(cond,$id)

    if {$keepnewline} {
        set data $tkex(data,$id)
    } else {
        set data [string trimright $tkex(data,$id) \n]
    }

    unset tkex(pipe,$id)
    unset tkex(data,$id)
    unset tkex(cond,$id)

    if {[catch {close $pipe} err]} {
        error "pipe error: $err"
    }

    return $data
}

# grasp sensor

# the quiet value of the sensor changes when it warms up.
# this squeeze code asks for an initial grasp voltage, which may vary.

proc hand_set_points {} {
    global ob
    set closed [rshm hand_gear_offset]
    set span [rshm hand_gear_span]
    set gap [rshm hand_gear_gap]

    # only clock has slotlength
    if {![info exists ob(slotlength)]} {
	set ob(slotlength) 0.14
    }
    # if small slotlength, small handspan too.
    if {$ob(slotlength) <= 0.10} {
	set span [expr {$span - 0.014}]
    }

    set open [expr {$closed + $span}]
    # if the range is bad, make everything 51 mm, so the hand just parks
    if {($open - $closed) < (2 * $gap)} {
        set open 0.051
        set closed 0.051
        set gap 0.0
    }

# usual clock spans:
# adult 34 38 42 66 70 74
# child 34 38 42 52 56 60

    # stop 4mm mvbox 4mm target .. (mirror)
    set ob(hand_closed_stop) $closed
    set ob(hand_closed_mvbox) [expr {$ob(hand_closed_stop) + $gap}]
    set ob(hand_closed_target) [expr {$ob(hand_closed_mvbox) + $gap}]
    set ob(hand_open_stop) $open
    set ob(hand_open_mvbox) [expr {$ob(hand_open_stop) - $gap}]
    set ob(hand_open_target) [expr {$ob(hand_open_mvbox) - $gap}]
}

proc start_grasp {{w .}} {
    global ob

    set ob(grasp_running) "true"
    set ob(grasp_state) "open"

    # puts "calibrating grasp voltage $gv"

    # if you mess with these values, make sure they stay in synch
    # between ob and shm.

    set ob(grasp_have) [rshm have_grasp]
    set ob(hand_have) [rshm have_hand]
    set ob(ft_have) [rshm have_ft]

    set ob(hand_gear_offset) [rshm hand_gear_offset]

    hand_set_points

    # handy if we're running with zworld
    ft_bias
}

proc stop_grasp {} {
    global ob

    set ob(grasp_running) "false"
}

# game calls this proc from its main loop
# it generates
# <<GraspPress>> when closed
# <<GraspRelease>> when open
# <<GraspMotion>> every sample in between

# hand_pos is raw meters
#
proc grasp_iter {{w .}} {
    global ob

    if {$ob(hand_have)} {
        set ob(hand_pos) [rshm hand_pos]
    } elseif {$ob(ft_have)} {
        set ob(zforce) [rshm ft_zworld]
        set ob(hand_pos) [expr {-$ob(zforce)}]
        set ob(hand_closed_target) 10.0
        set ob(hand_open_target) 5.0
    } else {
        # none of the above.
        set ob(hand_pos) 0.001
    }

    if {$ob(grasp_state) == "open"} {
        if {$ob(hand_pos) < $ob(hand_closed_target)} {
            set ob(grasp_state) "closed"
            event generate $w <<GraspPress>> -x $ob(screen,x) -y $ob(screen,y)
# puts "generate Press $ob(hand_pos)"
        }
    } else {
        if {$ob(grasp_state) == "closed"} {
            event generate $w <<GraspMotion>> -x $ob(screen,x) -y $ob(screen,y)
            if {$ob(hand_pos) > $ob(hand_open_target)} {
                set ob(grasp_state) "open"
                event generate $w <<GraspRelease>>
# puts "generate Release $ob(hand_pos)"
            }
        }
    }
}

# fill notearr with evenly tempered piano scale

proc initnotearr {} {
    global notearr

    set notestep [expr {pow(2.,(1./12.))}]

    # Hertz
    set lowA 27.5

    set curnote $lowA

    # 8 octaves
    foreach j {1 2 3 4 5 6 7 8} {
        # 12 notes per octave, using sharps
        foreach i {A A# B C C# D D# E F F# G G#} {
            # puts "$i,$j $curnote"
            set notearr($i,$j) $curnote
            # curnote accumulates error, but it's not signifigant.
            set curnote [expr {$curnote * $notestep}]
        }
    }
}

initnotearr

proc nbeep {i {note A} {len 50}} {
    global notearr

    switch $i {
    1 {exec beep -l $len -f $notearr($note,3) -D $len -n -l $len -f $notearr($note,4) &}
    2 {exec beep -l $len -f $notearr($note,4) -D $len -n -l $len -f $notearr($note,3) &}
    3 {exec beep -l $len -f $notearr($note,4) -D $len -n -l $len -f $notearr($note,6) &}
    4 {exec beep -l $len -f $notearr($note,6) -D $len -n -l $len -f $notearr($note,4) &}
    5 {exec beep -l $len -f $notearr($note,6) -D $len -n -l $len -f $notearr($note,8) &}
    6 {exec beep -l $len -f $notearr($note,8) -D $len -n -l $len -f $notearr($note,6) &}
    }
}

# read imt2.cal into imt2.cal()
proc read_cal {file} {
    global imt2.cal

    # commands in cal, ok or set or #
    proc ok {} {}
    proc s {name arg1 {arg2 ""}} {
        global imt2.cal
        if {$arg2 == ""} {
            set imt2.cal($name) $arg1
        } else {
            set imt2.cal(1,$name) $arg1
            set imt2.cal(2,$name) $arg2
        }
    }
    set fd [open $file r]
    set cal [read $fd]
    close $fd
    eval $cal
    # delete them
    rename ok ""
    rename s ""
}

# thermal model code.
# avoid use of the syllable temp or tmp for temperature,
# which can be confused with temporary.  use therm or tmpr instead.

# at game exit, writes a thermal_last file in imt_config,
# which it later reads in thermal_read_file at game entry.
# also writes a thermal_log file, for browsing only.
# when thermal_log grows too big, it gets copied to thermal_oldlog

# tries to deal gracefully with missing thermal_last/log files.

proc thermal_write_file {filename} {
    set have_tm [rshm have_thermal_model]
    if {! $have_tm} return

    set tmlastfile $::env(IMT_CONFIG)/${filename}_last
    set tmlogfile $::env(IMT_CONFIG)/${filename}_log
    set tmoldlogfile $::env(IMT_CONFIG)/${filename}_oldlog

    set have_planar [rshm have_planar]
    if {$have_planar} {

        # open
        # truncate and write to the last file
        set fd(last) [open $tmlastfile "w"]
        # trim log file
	if {[file exists $tmlogfile]
	 && [file size $tmlogfile] > 100000} {
            file rename -force $tmlogfile $tmoldlogfile
        }
        # append to the log file
        set fd(log) [open $tmlogfile "a"]

        # get data
        set pl_sh_tmpr_winding [rshm shoulder_tm_tmpr_winding]
        set pl_sh_tmpr_case [rshm shoulder_tm_tmpr_case]
        set pl_el_tmpr_winding [rshm elbow_tm_tmpr_winding]
        set pl_el_tmpr_case [rshm elbow_tm_tmpr_case]
        set secs [clock seconds]

	if {[isnan $pl_sh_tmpr_winding]} {set pl_sh_tmpr_winding 5.0}
	if {[isnan $pl_sh_tmpr_case]} {set pl_sh_tmpr_case 5.0}
	if {[isnan $pl_el_tmpr_winding]} {set pl_el_tmpr_winding 5.0}
	if {[isnan $pl_el_tmpr_case]} {set pl_el_tmpr_case 5.0}

        # write each temperature to files
        foreach f {last log} {
            puts $fd($f) "# thermal model - [clock format $secs]"
            puts $fd($f) "thset robot_type planar"
            puts $fd($f) "thset tm_secs $secs"
            puts $fd($f) "thset shoulder_tm_tmpr_winding $pl_sh_tmpr_winding"
            puts $fd($f) "thset shoulder_tm_tmpr_case $pl_sh_tmpr_case"
            puts $fd($f) "thset elbow_tm_tmpr_winding $pl_el_tmpr_winding"
            puts $fd($f) "thset elbow_tm_tmpr_case $pl_el_tmpr_case"
            puts $fd($f) ""
            close $fd($f)
        }
    }
}

# the time constant (for now) is about 1347 seconds.
# the motor windings cool about 63% in this time

proc thermal_time_decay {motor tmpr time} {
    set tmass_winding [rshm ${motor}_tm_tmass_winding]
    set tmass_case [rshm ${motor}_tm_tmass_case]
    set tres_winding [rshm ${motor}_tm_tres_winding]
    set tres_case [rshm ${motor}_tm_tres_case]

    set time_constant [expr {($tmass_winding + $tmass_case)
	* ($tres_winding + $tres_case)}]
    if {$time_constant < 1.0} {set time_constant 1.0}
    if {$time < 0.0} {set time 0.0}
    # puts "thermal_time_decay: time constant: $time_constant"
    return [expr {$tmpr * exp(-$time / $time_constant)}]
}

proc thermal_read_file {filename} {
    global therm
    set have_thermal_model [rshm have_thermal_model]
    if {! $have_thermal_model} return
    set have_planar [rshm have_planar]
    if {! $have_planar} return
    set tmlastfile $::env(IMT_CONFIG)/${filename}_last
    # should we set a funny default instead of returning?

    proc thset {name arg1} {
        global therm
        set therm($name) $arg1

    }

    if {[file exists $tmlastfile]} {
        set fd [open $tmlastfile r]
        set cmds [read $fd]
        close $fd
        eval $cmds
    }

    # if tm_secs does not exist, then either the file did not exist
    # or maybe it was empty or otherwise messed up.
    # in that case, reset the variables and go.

    if {![info exists therm(tm_secs)]} {
        thset robot_type planar
        thset tm_secs [expr {[clock seconds] - 5}]
        thset shoulder_tm_tmpr_winding 5.0
        thset shoulder_tm_tmpr_case 5.0
        thset elbow_tm_tmpr_winding 5.0
        thset elbow_tm_tmpr_case 5.0
    }

    if {[isnan $therm(shoulder_tm_tmpr_winding)]} {thset shoulder_tm_tmpr_winding 5.0}
    if {[isnan $therm(shoulder_tm_tmpr_case)]} {thset shoulder_tm_tmpr_case 5.0}
    if {[isnan $therm(elbow_tm_tmpr_winding)]} {thset elbow_tm_tmpr_winding 5.0}
    if {[isnan $therm(elbow_tm_tmpr_case)]} {thset elbow_tm_tmpr_case 5.0}

    rename thset ""

    # see how long we've waited and apply temp decays (not done)
    set secs [clock seconds]
    set dsecs [expr {$secs - $therm(tm_secs)}]

    # apply temps
    set stemp [thermal_time_decay shoulder $therm(shoulder_tm_tmpr_winding) $dsecs]
    wshm shoulder_tm_tmpr_winding $stemp
    wshm shoulder_tm_tmpr_case $stemp
    set etemp [thermal_time_decay elbow $therm(elbow_tm_tmpr_winding) $dsecs]
    wshm elbow_tm_tmpr_winding $etemp
    wshm elbow_tm_tmpr_case $etemp

# puts "thermal_read_file: it has been $dsecs seconds since the last write"
# puts "thermal_read_file: shoulder old $therm(shoulder_tm_tmpr_winding) new $stemp"
# puts "thermal_read_file: elbow old $therm(elbow_tm_tmpr_winding) new $etemp"
}

# like after, but lets the event loop run.
proc tksleep {time} {
    after $time set ::tksleep_end 1
    vwait ::tksleep_end
}

proc current_robot {} {
    exec cat $::env(IMT_CONFIG)/current_robot
}

proc have_plc {} {
    file exists $::env(IMT_CONFIG)/have_plc
}

proc have_c {} {
    if {[personality_is g2]} {
	return true
    } elseif {[personality_is ce]} {
	return [ have_plc ]
    }
}

# set robot calibration done,

proc set_robot_cal_done {} {
    if {[have_c]} {
	exec $::env(CROB_HOME)/tools/[personality]plc set-cal-en
    }
}

# clear robot calibration done

proc clear_robot_cal_done {} {
    if {[have_c]} {
	exec $::env(CROB_HOME)/tools/[personality]plc set-cal-dis
    } 
}

# is robot calibration done?

proc is_robot_cal_done {} {
    if {[have_c]} {
	set ret [catch {exec $::env(CROB_HOME)/tools/[personality]plc check-cal}]
	set ret [expr {!$ret}]
	return $ret
    } else {
	return true
    }
}

# is robot ready lamp on?

proc is_robot_ready {} {
    if {[have_c]} {
	set ret [catch {exec $::env(CROB_HOME)/tools/[personality]plc check-ready-lamp}]
	set ret [expr {!$ret}]
	return $ret
    } else {
	return 1
    }
}

# is robot plc running?

proc is_robot_plc_running {} {
    if {[personality_is ce]} {
	if {[have_c]} {
	    set ret [catch {exec $::env(CROB_HOME)/tools/[personality]plc check-plc}]
	    set ret [expr {!$ret}]
	    return $ret
	}
    } else {
	return 0
    }
}

# is a string a NaN?

proc isnan {x} {
    if {![string is double $x] || $x != $x} {
        return 1
    } else {
        return 0
    }
}


proc f3k {n} {
    format %.3f [expr {1000.0 * $n}]
}

# format each floating point arg as %.3f

proc f3 {args} {
    set ret {}
    foreach i $args {
        if {[string is double $i]} {
            lappend ret [format %.3f $i]
        } else {
            lappend ret $i
        }
    }
    return $ret
}

# calls docenter.  proc does not return a status, caller should check is_robot_cal_done

proc do_calibration {{req ""}} {
    global ob
    catch {exec $::env(CROB_HOME)/tools/docenter $req > /dev/tty} out
}

proc rangemap {a1 a2 b1 b2 value} {
    expr {$b1 + ($value - $a1) * double($b2 - $b1) / ($a2 - $a1)}
}

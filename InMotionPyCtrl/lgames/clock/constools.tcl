#!/usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# cons Game Console Tools menu helper procs

proc procname {} {
    lindex [info level 1] 0
}

proc consToolsAddNote {{dirname ""}} {
    global ob

    set dirname [file join $ob(tbasedir) $ob(patident)]

    if {![file isdirectory $dirname]} {
        error "Cannot read $dirname"
    }

    if {![string match $ob(tbasedir)/?* $dirname]} {
        error "Patient directory $dirname\n must be in $ob(tbasedir)."
    }

    set fname $dirname/note

    if {![file exists $fname]} {
        exec echo "Click at the bottom to add new note to the end of this file." >> $fname
        exec echo "Edit note, then Close Window and Save." >> $fname
    }

    exec echo "\n===========" >> $fname
    exec date >> $fname
    exec echo "Patient ID: $ob(patident)   Clinician: $ob(clinident)\n" >> $fname
    exec mousepad $fname > /dev/tty
}

proc consToolsShowPM4 {} {
    set ::ob(patident) $::env(PATID)
    show_pm4
}

proc consToolsLongTest { } {
    global ob env

    set ::env(PATID) test
    set protocols_base $::env(PROTOCOLS_HOME)
    set ob(current_robot) [current_robot]

    if {![is_robot_cal_done]} {
        do_calibration request
    }

    if {![is_robot_cal_done]} {
        return
    }

    if {$ob(current_robot) == "planar"} {
	exec /usr/bin/wish $::env(LGAMES_HOME)/clock/clock.tcl $protocols_base/planar/clock/adaptive/therapy/long_test test &
    }

    if {$ob(current_robot) == "planarhand"} {
	exec /usr/bin/wish $::env(LGAMES_HOME)/clock/clock.tcl $protocols_base/planarhand/clock/adaptivegrasp/therapy/long_test test &
    }

    if {$ob(current_robot) == "wrist"} {
	exec /usr/bin/wish $::env(LGAMES_HOME)/clock/clock.tcl $protocols_base/wrist/clock/adaptive/therapy/wr_long_test_ps test &
    }

}

proc consToolsChooseRobot {} {
    global ob

    if {![is_robot_ready]} {
	tk_messageBox -title Failed -message "The Ready lamp is not lit.\
	    Please release all Stop buttons,\
	    press the Start button, and try again."
	return
    }

    set rc [catch {eval exec [file join $ob(lgamesdir) config chooserobot.tcl] > /dev/tty &} out]
    # this may change the robot type and we're not waiting for it, so just exit here.
    consExit
}

proc consToolsFTTest { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools ft_test] > /dev/tty &} out]
}

proc consToolsDelete { {dirname ""} } {
    global ob

    set ob(tbasedir) $::env(THERAPIST_HOME)
    set dirlist [lsdir $ob(tbasedir)]
    set delnums [Dialog_List "Delete Folders" $dirlist]
    if { $delnums == "" } {
	return
    }
    # don't set initdir, you're deleting it.

    foreach i $delnums {
	set dirname [lindex $dirlist $i]
	if { $dirname == "" } {
	    return
	}
	set dirname [file join $ob(tbasedir) $dirname]

	if { ![file isdirectory $dirname] } {
	    error "Cannot read $dirname"
	}

	if {![string match $ob(tbasedir)/?* $dirname]} {
	    error "Cannot delete $dirname\n\
		Can only delete directories in $ob(tbasedir)."
	}

	set ret [tk_dialog .dial "Delete Directory" \
	    "Are you sure you want to delete $dirname and all its contents?" \
	    "" 1 "Yes, Delete" "No, Cancel"]
	# 0 is yes, 1 is Cancel.
	if {$ret == 0} {
	    file delete -force -- $dirname
	    tk_messageBox -title Deleted -message "$dirname deleted."
	} else {
	    tk_messageBox -title Cancelled -message "$dirname delete cancelled."
	}
    }
}

proc consToolsUSBCopy { {dirname ""} } {
    global ob

    set ob(tbasedir) $::env(THERAPIST_HOME)
    set dirlist [lsdir $ob(tbasedir)]
    set cpnums [Dialog_List "Copy Folders" $dirlist]
    if { $cpnums == "" } {
	return
    }

    set cplist {}
    foreach i $cpnums {
	lappend cplist [lindex $dirlist $i]
    }
    puts "eval exec [file join $ob(crobdir) tools usbcopy] $cplist"
    set rc [catch {eval exec [file join $ob(crobdir) tools usbcopy] $cplist} out]
}

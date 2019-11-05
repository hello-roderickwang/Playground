#!/usr/bin/wish

package require Tk

source $env(CROB_HOME)/shm.tcl
source $::env(LGAMES_HOME)/pups/consreport.tcl

# dispatch games
# create a button for each game,
# and call the game when its button is pressed.

proc cg_setup {} {
    global env ob cfg

    set ob(log_home) $::env(THERAPIST_HOME)
    set ob(lgames_home) $::env(LGAMES_HOME)
    set ob(config_home) $::env(IMT_CONFIG)
    set ob(i18n_home) $::env(I18N_HOME)

    set ob(base) $ob(lgames_home)
    cd $ob(base)/choosegame
    source $ob(base)/common/util.tcl
    source $ob(i18n_home)/i18n.tcl
    set ob(current_robot) [current_robot]
    source $ob(config_home)/robots/$ob(current_robot)/robot.cfg

    font create default -family Times -size -18
    option add *msg.font default
    option add *list.font default
    option add *buttons.font default

    set ob(tbasedir) $ob(log_home)
    # make sure it's there, in case it's new.
    file mkdir $ob(tbasedir)

    wm title . "Choose Game"
    wm geometry . +300+50

    frame .fpat
    frame .fclin
    frame .f0
    frame .f1
    frame .f2

    button .fpat.help -text [imes Help] -command consRptHelp -font default
    button .fpat.exit -text [imes Quit] -command exit -font default

    label .fpat.lab -text [imes "Patient ID:"] -font default
    set ob(patbut) [imes Select]
    button .fpat.listbut -textvariable ::ob(patbut) -font default -command selpat -width 12
    button .fpat.newbut -text [imes "New"] -font default -command newpat

    # do not pack these to start.
    entry .fpat.addent -textvariable ::ob(pataddent) -font default -width 15
    button .fpat.addbut -text [imes "Add"] -font default -command addpat

    label .fclin.lab -text [imes "Clinician:"] -font default
    set ::env(CLINID) ""
    entry .fclin.ent -textvariable ::env(CLINID) -font default -width 15

    pack .fpat -fill x
    pack .fclin -fill x
    pack .f0 .f1 .f2 -side left -anchor n

    pack .fpat.lab .fpat.listbut .fpat.newbut -side left -pady 10
    pack .fpat.exit -side right -padx 10
    pack .fpat.help -side right -padx 10

    pack .fclin.lab .fclin.ent -side left -pady 10
}

proc dorun {game} {
	global env ob

	# reap zombies
	exec true

	if {![info exists env(PATID)]} {
		error [imes "Please select Patient ID"]
	}
	if {$env(PATID) == ""} {
		error [imes "Please select Patient ID"]
	}
	if {$env(PATID) == "Select"} {
		error [imes "Please select Patient ID"]
	}

	set env(CLINID) [fnstring $env(CLINID)]
	if {![info exists env(CLINID)]} {
		error [imes "Please enter Clinician ID"]
	}
	if {$env(CLINID) == ""} {
		error [imes "Please enter Clinician ID"]
	}

        if {[is_lkm_loaded]} {
                error [imes "Robot program already running"]
        }

        # check all linear games but clock.
        # clock/cons has this check inside it, so you can get to cons
        # to run the cal
        if {[have_c]} {
            if {("$game" != "clock")} {
                if {![is_robot_cal_done]} {
                    do_calibration request

                    if {![is_robot_cal_done]} {
                        return
                    }
                }
            }
        }
        if {($ob(current_robot) == "linear") &&("$game" != "clock")} {
            if {![is_robot_cal_done]} {
                do_calibration request

                if {![is_robot_cal_done]} {
                    return
                }
            }
        }

	exec $ob(base)/$game/run$game &
}

proc selpat {} {
    global ob env

    # ls -1t (that's a one, not -lt)
    # to sort the patient folders in one column
    # by modification time newest first
    # can't do this with tcl glob
    set patlist [exec /bin/ls -1t $::env(THERAPIST_HOME)]
    if {$patlist == ""} {
	error "The patient list is empty."
    }
    set patnum [Dialog_List "Choose Patient ID" $patlist single]
    if {$patnum == ""} return
    set pat [lindex $patlist $patnum]
    set ob(patbut) $pat
    set env(PATID) $pat
}

proc newpat {} {
    pack forget .fpat.listbut .fpat.newbut
    pack .fpat.addent .fpat.addbut -side left -pady 10
}

proc addpat {} {
    global ob env
    pack forget .fpat.addent .fpat.addbut
    pack .fpat.listbut .fpat.newbut -side left -pady 10

    # make it a canonical file name string
    set patid [fnstring $ob(pataddent)]

    # do not remember for next time.
    set ob(pataddent) ""

    if {$patid == ""} return

    set ret [tk_dialog .dial "Add Patient" \
	"Are you sure you want to add patient \"${patid}\"?" \
	"" 1 "Yes, Add" "No, Cancel"]
    # 0 is yes, 1 is Cancel.
    if {$ret == 0} {
	tk_messageBox -title Add -message "Adding new patient \"${patid}\"."
    } else {
	tk_messageBox -title Cancel -message "New patient \"$patid\" add cancelled."
	return
    }

    set env(PATID) $patid
    set ob(patbut) $patid
    file mkdir [file join $ob(tbasedir) $patid]
}

proc cg_run {} {
    global cfg ob
    set n 0

    foreach i $cfg($ob(current_robot),games,list) {
	if {$cfg($ob(current_robot),$i,proto,sellist) != ""} {
	    lappend available_games $i
	}
    }

    set tclos [tclos]
    foreach i $available_games {
	    set f .f[expr {$n % 3}]
	    set im [image create photo -file $i.gif]
	    if [regexp ^(Linux|Unix|QNX) $tclos] {
		    set cmd [list dorun $i]
	    } else {
		    error "game exec"
	    }
	    button $f.$i -image $im -command $cmd -bd 5
	    bind $f.$i <Double-1> {after 700 {error [imes "please don't double-click the game buttons"]}; break}
	    bind $f.$i <Triple-1> {after 700 {error [imes "please don't triple-click the game buttons"]}; break}
	    pack $f.$i -padx 2 -pady 2
	    incr n
    }
}

proc cg {} {
    cg_setup
    cg_run
}

cg

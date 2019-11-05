#! /usr/bin/wish

# robot menu
# listbox of games per robot
# listbox of protocol per robot per game

package require Tk
package require BWidget

source $::env(CROB_HOME)/shm.tcl

# the BWidget ListBox isn't fully compatible with the 8.4 listbox,
# so we use the BWidget generic ScrolledWindow instead.

proc init {} {
    global ob cfg

    set ob(crobhome) $::env(CROB_HOME)
    
    set ob(cfgfile) robot.cfg
    set ob(config_base) $::env(IMT_CONFIG)

    # running config.tcl forces a recal,
    # whether you change anything or not.
    # clear robot calibration done

    clear_robot_cal_done

    set ob(proto_lab_text) "Enabled Protocols:"

    read_skel
    read_config

    set ob(robot,current,lab) "Configuration for Robot Type:"
    label .robot_lab -textvariable ob(robot,current,lab)
    menubutton .robot_but -textvariable cfg(robot,current) -menu .robot_but.m \
	    -relief raised
    menu .robot_but.m -tearoff 0

    # the robot frame and quit are gridded.

    button .scan -text Scan -command scan
    button .quit -text Quit -command quit
    grid .robot_lab .robot_but .scan .quit 
    grid .robot_lab
    grid .robot_but
    grid .quit -sticky e


    foreach i $ob(robot,list) {
	.robot_but.m add radio -label $i -value $i \
	    -variable cfg(robot,current) -command [list robot_changed $i]
    }

    # the games listbox

    # exportselection 0 lets the selection stay highlighted
    # when we leave the listbox.

    label .games_lab -text "Available Games:"
    ScrolledWindow .games
    listbox .games.lb -height 15 -width 80 -exportselection 0
    .games setwidget .games.lb

    games_populate

    grid .games_lab - - - -sticky w
    grid .games - - - -sticky news

    bind .games.lb <<ListboxSelect>> {games_changed %W}

    # the protocols listbox

    label .proto_lab -textvariable ob(proto_lab_text)
    ScrolledWindow .proto
    listbox .proto.lb -height 15 -width 80 -selectmode multiple
    .proto setwidget .proto.lb

    bind .proto.lb <<ListboxSelect>> {proto_changed %W}

    grid .proto_lab - - - -sticky w
    grid .proto - - - -sticky news

    # make the listboxes stretch in y
    grid rowconfigure . "2 4" -weight 1

    # make column 2 strech in x, so the top label:button stick together
    grid columnconfigure . 2 -weight 1

    wm title . "IMT Robot Games Protocol Configuration"
    wm protocol . WM_DELETE_WINDOW quit
}

proc get_first_robot {} {
    set savecwd [pwd]
    cd $::env(IMT_CONFIG)/robots
    set robotlist [glob *]
    set ret [lindex $robotlist 0]
    cd $savecwd
    return $ret
}

# read at init time

proc read_config {} {
    global ob cfg skel_cfg
    
    array unset cfg

    # the current robot type, often the only robot on the PC

    cd $ob(config_base)
    if {![file exists current_robot]} {
	set cfg(robot,current) [get_first_robot]
	if {$cfg(robot,current) == ""} {
	    error "imt_config/robots directory is empty, it must have some available robots"
	}
	
    } elseif {![file writable current_robot]} {
	error "file [file join $ob(config_base) current_robot] is not writable."
	exit
    }
    if {[file readable current_robot]} {
       set fd [open current_robot r]
       set cfg(robot,current) [gets $fd]
       if {![file exists [file join robots $cfg(robot,current)]]} {
          set cfg(robot,current) [get_first_robot]
       }
       close $fd
    }
    write_current_robot

    # read robot.cfg from each robot dir
    # this contains settings that accumulate in cfg()

    cd robots/
    set ob(robot,list) [glob *]
    foreach i $ob(robot,list) {
	source $i/$ob(cfgfile)
    }
}

proc read_skel {} {
    global ob skel_cfg

    cd /opt/imt/robot/skel
    set robotlist [glob *]
    foreach i $robotlist {
	source $i/$ob(cfgfile)
    }

    array set skel_cfg [array get cfg]
}

proc write_current_robot {} {
    global ob cfg

    cd $ob(config_base)
    set fd [open current_robot w]
    puts $fd $cfg(robot,current) 
    close $fd
}


# save cfgs at exit

proc save_config {} {
    global ob cfg


    write_current_robot

    cd $ob(config_base)/robots
    # save robot.cfg for each robot dir
    foreach i $ob(robot,list) {
	# puts "saving $i/$ob(cfgfile)"
	set fd [open $i/$ob(cfgfile) "w"]
	puts $fd "# this cfg file is usually written by the lgames/config program."
	puts $fd "# you may edit it yourself to add items to the"
	puts $fd "# games,list or proto,list entries"
	puts $fd "# [clock format [clock seconds]]"
	puts $fd ""
	puts $fd "array set cfg {"
	# save all per-robot cfg data in file
	foreach key [lsort [array names cfg $i,*]] {
	    puts $fd [list $key $cfg($key)]
	}
	puts $fd "}"
	close $fd
    }
}

proc scan {} {
    global ob cfg env
    set protohome $env(PROTOCOLS_HOME)
    set robot $cfg(robot,current)
    if {![info exists ob(game,current)]} {
	tk_messageBox -icon warning -message "Please select a game before running scan."
	return
    }
    set game $ob(game,current)
    set protodir [file join $protohome $robot $game]
    set protolist [lsort [glob -tails -types d -directory $protodir *]]

    if {$protolist == {}} {
	tk_messageBox -icon warning -message "Could not find new protocols."
	return
    }
    set cfg($robot,$game,proto,list) $protolist
    proto_populate $robot $game
    .proto.lb selection clear 0 end
    tk_messageBox -icon warning -message "Protocol list has been reset from protocol folder scan, please select desired protocols."
}

# quit button, and window X button

proc quit {} {
    save_config
    set robot $::cfg(robot,current)
    tk_messageBox -icon warning -message "Protocols for $robot robot have been set.  Please restart all robot programs.  Robot must be recalibrated before use after this reconfiguration."
    exit
}

# robot menu radiobutton callback

proc robot_changed {robot} {
    # puts "called robot_proc $robot"
    .games.lb selection clear 0 end
    .proto.lb delete 0 end
    games_populate
}

# when you change robots

proc games_populate {} {
    global cfg

    .games.lb delete 0 end
    set robot $cfg(robot,current)
    foreach i $cfg($robot,games,list) {
	.games.lb insert end $i
    }
}

# when you click a new game

proc games_changed {w} {
    global ob cfg

    set robot $cfg(robot,current)
    set game [lindex $cfg($robot,games,list) [$w curselection]]
    set ob(game,current) $game
    set ob(proto_lab_text) "Enabled $robot $game protocols (click to select or deselect desired protocols):"
    proto_populate $robot $game
}

# fill proto, when you click new game

proc proto_populate {robot game} {
    global ob cfg

    .proto.lb delete 0 end
    if {[info exists cfg($robot,$game,proto,list)]} {
	foreach i $cfg($robot,$game,proto,list) {
	    .proto.lb insert end $i
	}
    } else {
	set cfg($robot,$game,proto,list) default
	.proto.lb insert end default
    }
    # for each selected name,
    # search for its index in the proto list
    # and select it
    if {[info exists cfg($robot,$game,proto,sellist)]} {
	# puts "games_changed: these are selected: $cfg($robot,$game,proto,sellist)"
	foreach i $cfg($robot,$game,proto,sellist) {
	    .proto.lb selection set [lsearch $cfg($robot,$game,proto,list) $i]
	}
    }
}

# update cfg() when you change proto

proc proto_changed {w} {
    global ob cfg

    set robot $cfg(robot,current)
    set game $ob(game,current)

    set cfg($robot,$game,proto,sellist) {}

    foreach i [$w curselection] {
	lappend cfg($robot,$game,proto,sellist) [lindex $cfg($robot,$game,proto,list) $i]
    }
    # puts "proto_changed: proto sellist $robot $game: $cfg($robot,$game,proto,sellist)"
}

init

#! /usr/bin/wish

# robot menu
# listbox of games per robot
# listbox of protocol per robot per game

package require Tk

source $env(CROB_HOME)/shm.tcl

option add *Button.font {Helvetica 16 bold}
option add *Label.font {Helvetica 16 bold}
option add *Radiobutton.font {Helvetica 16 bold}

proc init {} {
    global ob cfg

    set ob(crobhome) $::env(CROB_HOME)
    
    set ob(cfgfile) robot.cfg
    set ob(config_base) $::env(IMT_CONFIG)

    # running config.tcl forces a recal,
    # whether you change anything or not.
    # clear robot calibration done

    clear_robot_cal_done

    
    get_robot_list
    read_config

    set ob(robot,current,lab) "Choose Robot Type"
    label .robot_lab -textvariable ob(robot,current,lab) -width 30
    grid .robot_lab

    foreach i $ob(robot,list) {
        radiobutton .b_$i -text $i -variable cfg(robot,current) -value $i
        grid .b_$i -sticky w
    }

    label .dummy1 -text ""
    label .dummy2 -text ""
    grid .dummy1
    grid .dummy2

    button .calibrate -text "Calibrate" -command calibrate
    grid .calibrate -sticky e

    wm title . "IMT Robot Chooser"
    wm protocol . WM_DELETE_WINDOW quit
}

proc get_robot_list {} {
    global ob

    set ob(robot,list) [glob -tails -directory $ob(config_base)/robots/ *]
}

proc get_first_robot {} {
    global ob

    set ret [lindex $ob(robot,list) 0]
    return $ret
}

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
}

proc write_current_robot {} {
    global ob cfg

    cd $ob(config_base)
    set fd [open current_robot w]
    puts $fd $cfg(robot,current)
    close $fd
}

# calibrate button, and window X button

proc calibrate {} {
    write_current_robot
    set robot $::cfg(robot,current)

    wm withdraw .

    do_calibration request

    exit
}

proc quit {} {
    exit
}

init

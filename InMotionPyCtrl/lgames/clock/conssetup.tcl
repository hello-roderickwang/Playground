#!/usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# cons Game Console Setup menu helper procs

proc procname {} {
	lindex [info level 1] 0
}

proc consSetupChooseVer { } {
    global ob
    set rc [catch {eval exec gksudo --preserve-env [file join $ob(crobdir) tools choosever] > /dev/tty &} out]
    # this changes lots of stuff, so exit.
    consExit
}

proc consSetupReconfig { } {
    global ob
    set rc [catch {eval exec [file join $ob(lgamesdir) config config.tcl] > /dev/tty &} out]
}

proc consSetupEditCalFile { } {
    global ob
    set ob(current_robot) [current_robot]
    set ob(imt_config) $::env(IMT_CONFIG)
    set rc [catch {eval exec mousepad [file join $ob(imt_config) robots $ob(current_robot) imt2.cal] > /dev/tty &} out]
}

proc consSetupDisplay { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools display] > /dev/tty &} out]
}

proc consSetupVex { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) vex] > /dev/tty &} out]
}

proc consSetupSlotDemo { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools slotdemo] > /dev/tty &} out]
}

proc consSetupMove { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools move] > /dev/tty &} out]
}

proc consSetupMvbox { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools mvbox.tcl] > /dev/tty &} out]
}

proc consSetupMTest { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools motor_tests] > /dev/tty &} out]
}

proc consSetupRStrip { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools rstrip] > /dev/tty &} out]
}

proc consSetupECal { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools ecal] > /dev/tty &} out]
}

proc consSetupReconf {} {
    global ob
    set rc [catch {eval exec [file join $ob(lgamesdir) config config.tcl] > /dev/tty &} out]
    # this may change the robot type and we're not waiting for it, so just exit here.
    consExit
}

proc consSetupFCal { } {
    global ob
    set rc [catch {eval exec [file join $ob(crobdir) tools ceforcecenter] > /dev/tty &} out]
}

proc consSetupExit { } {
    exit
}

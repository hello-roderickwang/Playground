# toplevel menu
# companion to games
# button, text, and variables
#

proc menu_init {w} {
	global mob ob
	toplevel $w
	if [info exists ob(programname)] {
		set title $ob(programname)
	} else {
		set title game
	}
	wm title $w "$title menu"
	wm geometry $w 200x600-50+50

	bind . <Alt-m> "menu_hide $w"
	bind $w <Alt-m> "menu_hide $w"
	wm protocol $w WM_DELETE_WINDOW [list menu_hide $w]
	set mob(showing) 0
	wm withdraw $w

	return $w
}

proc menu_hide {w} {
	global mob
	if { $mob(showing) } {
		set mob(showing) 0
		wm withdraw $w
	} else {
		set mob(showing) 1
		wm deiconify $w
	}
}

proc menu_b {w name text cmd} {
	global mob
	frame $w.$name
	button $w.$name.but -text $text -command $cmd

	pack $w.$name -anchor w
	pack $w.$name.but
}

proc menu_t {w name labtext {val 0}} {
	global mob
	frame $w.$name
	label $w.$name.lab -text $labtext
	label $w.$name.var -textvariable mob($name)
	set mob($name) $val

	pack $w.$name -anchor w
	pack $w.$name.lab $w.$name.var -side left
}

proc menu_v {w name labtext {val 0}} {
	global mob
	frame $w.$name
	label $w.$name.lab -text $labtext
	entry $w.$name.ent -textvariable mob($name)
	set mob($name) $val

	pack $w.$name -anchor w
	pack $w.$name.lab $w.$name.ent -side left
}

proc menu_cb {w name text} {
	global mob
	frame $w.$name
	checkbutton $w.$name.cbut -text $text -variable mob($name)

	pack $w.$name -anchor w
	pack $w.$name.cbut
}


proc clockms7 {} {
	return [clock clicks]
}

proc clockms8 {} {
	return [clock clicks -mill]
}

if {[tclvmaj] < 8} {
	rename clockms7 clockms
} else {
	rename clockms8 clockms
}

proc clock_start {} {
	global ob mob

	set ob(t0) [clockms]
	set mob(time) 0
	set ob(stopclock) 0
	set ob(clock) [after 475 doclock]
}

proc clock_stop {} {
	global ob mob

	# if a person hits stop twice, don't mess with the time again.
	if {$ob(stopclock) == 0} {
		set mob(time) [format %.2f [expr {(double([clockms]) - $ob(t0))/1000}]]
	}
	set ob(stopclock) 1
	after cancel doclock
}

proc doclock {} {
	global ob mob

	if {$ob(stopclock)} { return }
	set mob(time) [expr {([clockms] - $ob(t0))/1000}]
	set ob(clock) [after 475 doclock]
	# update idletasks
}

proc g_log_start {{game "game"} {patid "patid"} {type "therapy"} {nlog 8} {logfnid 0}} {
    global ob env

    set ob(logdirbase) $::env(THERAPIST_HOME)
    set ob(patname) $patid
    set ob(tailname) $game
    set ob(gametype) $type
    set ob(logvars) $nlog

    set curtime [clock seconds]
    set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    set ob(dirname) [file join $ob(logdirbase) $ob(patname) \
      $ob(gametype) $ob(datestamp) ]

    set logfilename [join [list $ob(tailname) $ob(timestamp).dat] _]
    set logfilename [file join $ob(dirname) $logfilename]
    puts "start_log $logfilename $ob(logvars)"
    wshm logfnid $logfnid
    start_log $logfilename $ob(logvars)
}

proc g_log_stop {} {
puts "stopping log"
    stop_log
puts "log stopped"
}

proc trymenu {w} {
	global mob

	wm geometry . 800x800+50+50

	menu_t $w one One
	menu_t $w two Two 
	menu_v $w three Three
	menu_b $w bye Bye {exit}

	set mob(one) 1
	set mob(two) 2
	set mob(three) 3
}

# set w [menu_init .menu]

# trymenu $w


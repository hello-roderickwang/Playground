# util routines

source $::env(CROB_HOME)/shm.tcl

proc plist {l} {
    # foreach i $l {puts [list $i]}
    join $l \n
}

proc bracket {n min max} {
    if { $n < $min } { return $min }
    if { $n > $max } { return $max }
    return $n
}

proc min {a b} {
    if { $a < $b } {
	    return $a
    } else {
	    return $b
    }
}

proc max {a b} {
    if { $a > $b } {
	    return $a
    } else {
	    return $b
    }
}

# calculate Euclidean distance.  (Why not Pythagorean?)
proc edist {x1 y1 x2 y2} {
    expr {hypot($x1 - $x2, $y1 - $y2)}
}

# K combinator, a subtle tcl operator,
# makes some operations simpler and more efficient.
# return x, do y as a side-effect.
# don't worry about it, or see:
# http://mini.net/tcl/k
# shuffle uses K.

proc K {x y} {
    set x
}

# shuffle items in a list (like a deck of cards)

proc shuffle {list} {
    set n [llength $list]
    if {$n == 0} {return {}}
    while {$n>0} {
	set j [expr {int(rand() *$n)}]
	lappend slist [lindex $list $j]
	incr n -1
	set temp [lindex $list $n]
	set list [lreplace [K $list [set list {}]] $j $j $temp]
    }
    return $slist
}

# generate 0 .. n-1

proc iota {n} {
    for {set i 0} {$i < $n} {incr i} {
	lappend retval $i
    }
    return $retval
}

# return a shuffled list of s sets of i items.
# if s is 10 and i is 3, it will return 30 of digits,
# 10 0's, 10 1's, 10 2's, in random order.
proc make_rand_list {s i} {
    set loc_list {}
    foreach j [iota $s] {
	lappend loc_list [iota $i]
    }
    return [shuffle [join $loc_list]]
}

proc arrayunset {args} {
    foreach aname $args {
	upvar $aname a
	if [array exists a] {
	    foreach i [array names a] {
		unset a($i)
	    }
	    unset a
	}
    }
}

# mirror about / axis
proc swaps {args} {
    global ob

    if {$ob(hdir) == "0"} {return $args}

    set l {}
    foreach {a b} $args {
	    lappend l $b $a
    }
    return $l
}

# rotate cw 90 degrees
proc nswaps {args} {
    global ob

    if {$ob(hdir) == "0"} {return $args}

    set l {}
    foreach {a b} $args {
	    set a [expr {-$a}]
	    lappend l $b $a
    }
    return $l
}

proc irand8 {i} {
    expr {int(rand() * $i)}
}

global _ranseed
set _ranseed [clock seconds]
proc irand7 {i} {
    global _ranseed
    set _ranseed [expr ($_ranseed * 9301 + 49297) % 233280]
    return [expr int($i * ($_ranseed / double(233280)))]
}

proc tclvmaj {} {
    regsub \\..* [info tclversion] "" v
    return $v
}

proc tclos {} {
    global tcl_platform

    return $tcl_platform(os)
}

if {[tclvmaj] < 8} {
    rename irand7 irand
} else {
    rename irand8 irand
}

global _nexti
set _nexti 0
proc nexti {} {
    global _nexti
    incr _nexti
}

# from bw's book
# intialize varname if it doesn't already exist.
proc incr {varName {amount 1}} {
    upvar 1 $varName var
    if {[info exists var]} {
	    set var [expr {$var + $amount}]
    } else {
	    set var $amount
    }
    return $var
}

proc glog {str} {
    global env ob

    set cstr [clock format [clock seconds] -format "%y/%m/%d %H:%M:%S"]
    if {![info exists ob(programname)]} {
	set ob(programname) game
    }
    set progn $ob(programname)
    if {$progn == "clock"} {
	set progn "$ob(programname)-$ob(gamename)"
    }
    if {[info exists env(PATID)]} {
	    set patient $env(PATID)
    } else {
	    set patient unknown
    }

    set patient [fnstring $patient]

    if {![info exists ob(logdirbase)]} {
	set ob(logdirbase) $::env(THERAPIST_HOME)
    }

    set logdir [file join $ob(logdirbase) $patient]
    set logf [file join $logdir games.log]
    file mkdir $logdir
    set f [open $logf a+]
    puts $f "$cstr $progn \{$patient\} $str"
    close $f
}

# make a file name string
proc fnstring {str} {
    set str [string tolower $str]
    regsub -all {[^0-9a-z]} $str {} str
    return $str
}

proc check_newpat {pat} {
    global ob
    set ret 1
    set fpat [fnstring $pat]
    if {![file isdirectory [file join $ob(tbasedir) $fpat]]} {
        set ret [tk_dialog .dial "New Patient" \
            [imes "Do you want to add the new patient %s?" $pat ] \
            "" 0 [imes "Yes, Add"] [imes "No, Cancel"]]
        # 0 is yes, 1 is Cancel.
        set ret [expr !$ret]
        # now 1 is yes, 0 is Cancel.
    }
    return $ret
}

# from bw's book p 430

proc Scroll_Set {scrollbar geoCmd offset size} {
    if {$offset != 0.0 || $size != 1.0} {
	    eval $geoCmd
	    $scrollbar set $offset $size
    } else {
	    set manager [lindex $geoCmd 0]
	    $manager forget $scrollbar
    }
}

proc Scrolled_Listbox { f args } {
    frame $f
    listbox $f.list \
	    -xscrollcommand [list Scroll_Set $f.xscroll \
		    [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
	    -yscrollcommand [list Scroll_Set $f.yscroll \
		    [list grid $f.yscroll -row 0 -column 1 -sticky ns]]
    eval {$f.list configure} $args
    scrollbar $f.xscroll -orient horizontal \
	    -command [list $f.list xview]
    scrollbar $f.yscroll -orient vertical \
	    -command [list $f.list yview]
    grid $f.list $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    return $f.list
}

# e.g.:
# Scrolled_Listbox .lb -width 10 -height 1

# pack .lb

# .lb.list insert end fazfaz
# .lb.list insert end yowza

proc Scrolled_Text { f args } {
    frame $f
    eval {text $f.text \
	    -xscrollcommand [list $f.xscroll set] \
	    -yscrollcommand [list $f.yscroll set]} $args
    scrollbar $f.xscroll -orient horizontal \
	    -command [list $f.text xview]
    scrollbar $f.yscroll -orient vertical \
	    -command [list $f.text yview]

    grid $f.text $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    return $f.text
}

# set t [Scrolled_Text .f -width 40 -height 8]
# pack .f -side top -fill both -expand true
# set in [open /etc/passwd]
# $t insert end [read $in]
# close $in

set ob(scorefont) {Arial 48}

#
# Example 39-1
# Procedures to help build dialogs.
#

proc Dialog_Create {top title args} {
    global dialog
    if [winfo exists $top] {
	    switch -- [wm state $top] {
		    normal {
			    # Raise a buried window
			    raise $top
		    }
		    withdrawn -
		    iconic {
			    # Open and restore geometry
			    wm deiconify $top
			    catch {wm geometry $top $dialog(geo,$top)}
		    }
	    }
	    return 0
    } else {
	    eval {toplevel $top} $args
	    wm title $top $title
	    return 1
    }
}
proc Dialog_Wait {top varName {focus {}}} {
    upvar $varName var

    # Poke the variable if the user nukes the window
    bind $top <Destroy> [list set $varName cancel]

    # Grab focus for the dialog
    if {[string length $focus] == 0} {
	    set focus $top
    }
    set old [focus -displayof $top]
    focus $focus
    catch {tkwait visibility $top}
    catch {grab $top}

    # Wait for the dialog to complete
    tkwait variable $varName
    catch {grab release $top}
    focus $old
}
proc Dialog_Dismiss {top} {
    global dialog
    # Save current size and position
    catch {
	    # window may have been deleted
	    set dialog(geo,$top) [wm geometry $top]
	    # wm withdraw $top
	    wm withdraw $top
    }
}

#
# Example 39-2
# A simple dialog.
#

proc Dialog_Prompt { string } {
    global prompt
    set f .prompt
    if [Dialog_Create $f "" -borderwidth 10] {
	    message $f.msg -text $string -aspect 1000
	    entry $f.entry -textvariable prompt(result)
	    set b [frame $f.buttons]
	    pack $f.msg $f.entry $f.buttons -side top -fill x
	    pack $f.entry -pady 5
	    button $b.ok -text OK -command {set prompt(ok) 1}
	    button $b.cancel -text Cancel \
		    -command {set prompt(ok) 0}
	    pack $b.ok -side left
	    pack $b.cancel -side right
	    bind $f.entry <Return> {set prompt(ok) 1 ; break}
	    bind $f.entry <Control-c> {set prompt(ok) 0 ; break}
    }
    set prompt(ok) 0
    Dialog_Wait $f prompt(ok) $f.entry
    Dialog_Dismiss $f
    if {$prompt(ok)} {
	    return $prompt(result)
    } else {
	    return {}
    }
}

proc Dialog_List {string inlist {selmode multiple}} {
    global dlist
    set f .dlist
    if {[winfo exists $f]} {destroy $f}
    if [Dialog_Create $f "" -borderwidth 10] {
	message $f.msg -text $string -aspect 1000
	set dlist(inlist) $inlist
	# entry $f.entry -textvariable dlist(result)
	Scrolled_Listbox $f.lb
	$f.lb.list config -selectmode $selmode -listvariable dlist(inlist)
	set b [frame $f.buttons]
	pack $f.msg $f.lb $f.buttons -side top -fill x
	pack $f.lb -pady 5 -fill both -expand true
	button $b.ok -text OK -command {set dlist(ok) 1}
	button $b.cancel -text Cancel \
		-command {set dlist(ok) 0}
	pack $b.ok -side left
	pack $b.cancel -side right
    }
    set dlist(ok) 0
    # Dialog_Wait $f dlist(ok) $f.entry
    Dialog_Wait $f dlist(ok) $f.lb
    Dialog_Dismiss $f
    # if person hits x
    if {![winfo exists $f.lb.list]} return {}
    set dlist(result) [$f.lb.list curselection]
    if {$dlist(ok)} {
	    return $dlist(result)
    } else {
	    return {}
    }
}

# For consRptCalc, like Dialog_List, but with a recomp CheckButton.
# returns a list of patients
# but first list element returned is 1 or 0,
# indicating whether to fully recompute or to use cached data.

proc CBDialog_List {string inlist {selmode multiple}} {
    global dlist
    set f .dlist
    if {[winfo exists $f]} {destroy $f}
    if [Dialog_Create $f "" -borderwidth 10] {
	message $f.msg -text $string -aspect 1000
	set dlist(inlist) $inlist
	# entry $f.entry -textvariable dlist(result)
	Scrolled_Listbox $f.lb
	$f.lb.list config -selectmode $selmode -listvariable dlist(inlist)
	set b [frame $f.buttons]
	set dlist(dorecomp) 0
	checkbutton $b.recomp -text Recompute -variable ::dlist(dorecomp)
	pack $f.msg $f.lb $f.buttons -side top -fill x
	pack $f.lb -pady 5 -fill both -expand true
	pack $b.recomp -pady 5 -fill both -expand true
	button $b.ok -text OK -command {set dlist(ok) 1}
	button $b.cancel -text Cancel \
		-command {set dlist(ok) 0}
	pack $b.ok -side left
	pack $b.cancel -side right
    }
    set dlist(ok) 0
    # Dialog_Wait $f dlist(ok) $f.entry
    Dialog_Wait $f dlist(ok) $f.lb
    Dialog_Dismiss $f
    # if person hits x
    if {![winfo exists $f.lb.list]} return {}
    set dlist(result) [$f.lb.list curselection]
    if {$dlist(ok)} {
	    return [concat $dlist(dorecomp) $dlist(result)]
    } else {
	    return {}
    }
}

# call this to find out whether we're a planar or wrist, etc

proc localize_robot {} {
	global env
	set lgames_home $::env(LGAMES_HOME)

	source $lgames_home/common/local.tcl
	# exec beep
}

proc current_robot {} {
    exec cat $::env(IMT_CONFIG)/current_robot
}

proc current_protocol {game {default_proto default}} {
    set proto_dir $::env(IMT_CONFIG)/robots/[current_robot]/$game
    set proto_file [file join $proto_dir current_protocol.cfg]
    
    if {![file exists $proto_file]} {
	file mkdir $proto_dir
        exec echo $default_proto > $proto_file
    }

    exec cat $proto_file
}

# always use $THERAPIST_HOME/$ob(patname)/be.log
# also write sanitized entry to /var/log/imt/be-yyyy-mm.log
# be is for begin/end.
# begin and end are for sessions, start and stop are for games.
# generate date and time strings.
# calculate difftime (in seconds) for timings
# print date, time, abstime, and string
# abstime may be good for i18n later
# print to file and stdout
# close file
# do not repeat log messages if people press stop button
# while already stopped

proc game_log_entry {rectype {str ""}} {
    global ob
    set curtime [clock seconds]
    set stamp [clock format $curtime -format "%Y/%m/%d.%a %H:%M:%S"]
    set shortstamp [clock format $curtime -format "%H:%M:%S"]

    set difftime 0
    switch $rectype {
	begin {
	    set ob(gle_begin) $curtime
	}
	end {
	    set difftime [expr {$curtime - $ob(gle_begin)}]
	}
	startgame {
	    set ob(gle_running) 1
	}
	stopgame {
	    if {! [info exists ob(gle_running)]} return
	    if {! $ob(gle_running) } return
	    set ob(gle_running) 0
	}
    }

    file mkdir [file join $ob(logdirbase) $ob(patname)]
    set logfile [file join $ob(logdirbase) $ob(patname) be.log]

    set lfp [open $logfile a]
    # perhaps add clinician name later
    set ob(clinname) cn
    if {[info exists ::env(CLINID)] && $::env(CLINID) != ""} {
	set ob(clinname) $::env(CLINID)
    }
    puts $lfp "$stamp $curtime $rectype $difftime $ob(patname) $ob(clinname) $ob(programname) $str"
    close $lfp

    # also log to the system usage log
    set syslogfile /var/log/imt/be-[clock format $curtime -format "%Y-%m"].log
    set lfp [open $syslogfile a]
    puts $lfp "$stamp $curtime $rectype $difftime x x $ob(programname) $str"
    close $lfp
    file attributes $syslogfile -permissions 0777

    puts "$shortstamp $rectype $difftime $ob(programname) $str"
}

# show pm4 metric file on display

proc show_pm4 {} {
	global ob

        set ob(logdirbase) $::env(THERAPIST_HOME)
	set fn4 $ob(logdirbase)/$ob(patident)/clock_pm4.asc
	if {[file readable $fn4]} {
		after 1000 exec ./gppm2.tcl $fn4 > /dev/tty &
	}
}

# list patient directories

proc patlsdir {dir} {
        set owd [pwd]
        cd $dir
        # assume that patient id's are numeric, so show most recent first
        set lslist [lsort -decreasing [glob -type d *]]
        cd $owd
        return $lslist
}

# list files

proc lsdir {dir} {
        set owd [pwd]
        cd $dir
        set lslist [glob *]
        cd $owd
        return $lslist
}

proc tksleep {time} {
    after $time set ::tksleep_end 1
    vwait ::tksleep_end
}

# status message on the bottom line
# if there's a cond, it must be true

proc status_mes {mes {cond true}} {
    global ob
    if {$cond} {
        set ob(status) $mes
    }
}

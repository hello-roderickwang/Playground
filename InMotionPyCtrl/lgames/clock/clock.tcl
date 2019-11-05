#! /usr/bin/wish
# vim: tabstop=8 noexpandtab

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 9/2000

##### original comments:

# user moves cursor to touch blinking ball,
# then blinking ball changes.
# alternating between center ball and edge balls.

# to make the game challenging, you may enter a threshold time
# in milliseconds, and if you keep a floating average (over the last
# 10 hits) below that number, the face stays green, or else it changes
# to red.

# the number of spots on the perimeter may be specified (default 8).
# the travel of the ball may be set to different increments, or
# to random.

##### end original comments

# new comments, rtlinux port, 1/2004
# japanese i18n 3/2004
# more cleanup 7/2004

# This clock game is the basis of a battery of therapy and
# evaluation games.  These games are all variations on the clock game,
# with different settings specified in the games/ directory.

# this file contains a bunch of procs, and one call to main.

# Tk GUI library
package require Tk
package require counter

global ob

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

# print a stack trace
proc call_trace {{file stdout}} {
    puts $file "Tcl Call Trace"
    for {set x [expr {[info level] -1}]} {$x > 0} {incr x -1} {
	puts $file "$x: [info level $x]"
    }
}

# create a star
# at position $pos
# with inner size [lindex $size 0]
# and outer size [lindex $size 1]
# rotated by $rot degrees
# with $n sparkles

# see http://mini.net/tcl/6096
# Ulrich Schoebel

# generate a random integer between from (inclusive) and to (exclusive)
proc random {from to} {
  return [expr {int(($to - $from)*rand()+$from)}]
}

proc clock_ft_dobias {} {
    ft_bias
}

proc star {{pos {200 200}} {size {40 100}} {rot -18} {n 5}} {
  set rot [expr {3.14159 * $rot / 180.0}]
  set inc [expr {6.28318 / $n}]
  foreach {xpos ypos} $pos break
  foreach {mind maxd} $size break
  for {set i 0} {$i < $n} {incr i} {
    lappend star [expr {cos($inc * $i + $rot) * $maxd / 2.0 + $xpos}]
    lappend star [expr {sin($inc * $i + $rot) * $maxd / 2.0 + $ypos}]
    lappend star [expr {cos($inc * ($i + 0.5) + $rot) * $mind / 2.0 + $xpos}]
    lappend star [expr {sin($inc * ($i + 0.5) + $rot) * $mind / 2.0 + $ypos}]
    }
  return $star
  }

# print info on all current pending after events

proc after_info {} {foreach id [after info] {puts "$id [after info $id]"}}

# cancel all after events that exactly match substring needle

proc after_cancel_match {needle} {
    foreach id [after info] {
        foreach {script type} [after info $id] break
        if {[string first $needle $script] >= 0} {
            after cancel $id
        }
    }
}

# show path if person hits p

proc do_path {} {
    global ob
    set ob(dopath) [expr {!$ob(dopath)}]
    if {!$ob(dopath)} {
        $ob(bigcan) delete path
    }
}

proc path_tick {x y} {
    global ob

    incr ob(dopathi)
    $ob(bigcan) create oval [centxy $x $y .002] -fill thistle -tags [list path_$ob(dopathi) path]
    $ob(bigcan) scale path_$ob(dopathi) 0 0 $ob(scale) -$ob(scale)
    $ob(bigcan) raise cursor
    after 5000 $ob(bigcan) delete path_$::ob(dopathi)
}

# counter aliases
interp alias {} ctadd {} ::counter::count
interp alias {} ctget {} ::counter::get
interp alias {} ctinit {} ::counter::init
interp alias {} ctreset {} ::counter::reset

# main
# this proc is called once (at the bottom of this file)
# when the program is first run.

proc main {} {
    global ob argc argv

    # game name and patient name
    # they come in as command line args, usually from the
    # cons "game console" program
    # in a HIPAA setting, the patient name will be a numeric ID.

    set ob(gamename) games/eval/test_log_frc
    set ob(patname) dfltpat

    if {$argc >= 1} {
	set ob(gamename) [lindex $argv 0]
    }
    if {$argc >= 2} {
	set ob(patname) [lindex $argv 1]
    }

    # put the game and patient name in the title bar
    wm title . "$ob(gamename) $ob(patname)"

    # read in game support procs
    source $::env(LGAMES_HOME)/common/util.tcl
    source $::env(LGAMES_HOME)/common/menu.tcl

    set ob(patname) [fnstring $ob(patname)]

    source $::env(I18N_HOME)/i18n.tcl

    # what kind of robot?  planar, wrist, etc
    localize_robot

    # set ob(programname) clock-$ob(gamename)
    set ob(programname) clock
    font create default -family Times -size -18

    # if you want to run with no arm and mouse cursor,
    # uncomment this following line:

    # no_arm

    # this initializes a bunch of variables, called once.
    onceg1

    game_log_entry begin $ob(gamename)
    game_log_entry startgame $ob(gamename)

    # this starts the game, may be called many times.
    # it is also bound to the n (new game) key.
    restartg1
}

# for init files
# the s command means "set."  for instance, there is a variable called
# "log" to turn on logging.  if the game init file has the line:
#	s log yes
# then this proc will:
#	set ob(log) yes

proc s {name val} {
    global ob
    set ob($name) $val
}

# toggle movebox status messages

proc toggle_sm_movebox {} {
    global ob
    set ob(sm_movebox) [expr {!$ob(sm_movebox)}]
}

# toggle beep if user hits b
# nbeep sends different 2-tone beeps depending on numbered arg 1-6
# clock_beep sends beeps only of dobeep is set

proc toggle_beep {} {
    global ob
    set ob(dobeep) [expr {!$ob(dobeep)}]
}

proc clock_beep {args} {
    global ob
    if {$ob(dobeep)} {
	nbeep $args
    }
}

# read the init file for the game specified.
# these flies consist of s (set) commands, and source commands, which
# read other init files.  this allows the differences between similar
# games to be described in a simple way.

proc read_game_init {gamefilename} {
    set odir [pwd]
    # normalize isn't available until tcl 8.4.  not that important.
    # set dir [file normalize [file join [pwd] [file dirname [info script] ... ]]]
    set dir [file join [pwd] [file dirname [info script]]\
      [file dirname $gamefilename] ]
    set tail [file tail $gamefilename]
    if {[file isdirectory $dir]} {
	cd $dir
	# puts "cd $dir"
    } else {
	error "read_game_init: can't source $dir $tail"
    }
    if {[file exists $tail]} {
	source $tail
	# puts "source $gamefilename"
    } else {
	error "read_game_init: can't source $dir $tail"
    }
    cd $odir
}

# after the game init variables are set in the GUI program, some of
# the values need to be sent to the control loop in the Linux Kernel
# Module (using wshm - write shared memory), and some other values
# need to be calculated.

proc apply_init_vars {} {
    global ob
    wshm offset_x $ob(centerx)
    wshm offset_y $ob(centery)

    # note that adap-specific inits happen in init_adap,
    # don't put them here.

    if {$ob(wrist)} {
	wshm wrist_diff_damp $ob(wrist_diff_damp)
	wshm wrist_ps_damp $ob(wrist_ps_damp)
	wshm wrist_diff_stiff $ob(wrist_diff_stiff)
	wshm wrist_ps_stiff $ob(wrist_ps_stiff)
    }
    if {$ob(linear)} {
	wshm linear_stiff $ob(linear_stiff)
	wshm linear_damp $ob(linear_damp)
    }

    if {$ob(planarwrist)} {
 	wshm wrist_diff_damp $ob(wrist_diff_damp)
 	wshm wrist_ps_damp $ob(wrist_ps_damp)
 	wshm wrist_diff_stiff $ob(wrist_diff_stiff)
 	wshm wrist_ps_stiff $ob(wrist_ps_stiff)
    }

    if {$ob(planarhand)} {
 	wshm hand_stiff $ob(hand_stiff)
 	wshm hand_damp $ob(hand_damp)
    }

    wshm curl $ob(curl)

    wshm restart_stiff $ob(stiff)
    wshm restart_damp $ob(damp)
    wshm restart_Hz $ob(Hz)
    wshm restart_go 1

    # fix bug that restart_stiff/damp were removed but still used
    after 50
    wshm stiff $ob(stiff)
    wshm damp $ob(damp)

    wshm logfnid $ob(logfnid)

    # wait before trip to edge (ms)
    # k here means thousands
    set ob(kpre_wait) [expr {int($ob(pre_wait) * 1000)}]
    set ob(kvlim_wait) [expr {int($ob(vlim_wait) * 1000)}]

    # per slot implies log
    if {$ob(logperslot)} {set ob(log) "yes"}
}

# initialize the compass directions, happens when game is re/started
# needs to be tweaked for random, to redo each circuit.

proc dodirlist {} {
    global ob

    if {$ob(linear)} {
        set ob(dirs)    { N S }
        set ob(dirnums) { 0 1 }
    } elseif {$ob(wrist_ps)} {
	set ob(dirs)    { E W }
	set ob(dirnums) { 0 1 }
    } elseif {$ob(wrist_fe)} {
	set ob(dirs)    { E W }
	set ob(dirnums) { 0 1 }
    }

    # the center is initally tagged as nextball,
    # this tag moves when a ball is touched.

    set idirlist {}

    if {$ob(proto_dirs4+)} {
	set ndirs [llength $ob(dirs4+)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirs4+)
	}
    } elseif {$ob(proto_dirs4x)} {
	set ndirs [llength $ob(dirs4x)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirs4x)
	}
    } elseif {$ob(nfan)} {
	set ndirs [llength $ob(dirsnfan)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirsnfan)
	}
    } elseif {$ob(sfan)} {
	set ndirs [llength $ob(dirssfan)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirssfan)
	}
    } elseif {$ob(efan)} {
	set ndirs [llength $ob(dirsefan)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirsefan)
	}
    } elseif {$ob(wfan)} {
	set ndirs [llength $ob(dirswfan)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirswfan)
	}
    } else {
	# default
	set ndirs [llength $ob(dirs)]
	set nsets [expr {$ob(nslots) / $ndirs}]

	for {set i 0} {$i < $nsets} {incr i} {
	    lappend idirlist $ob(dirs)
	}
    }
    set idirlist [join $idirlist]

    set nslots2 [expr {$ob(nslots) / 2 - 1}]

    # randomize the list in two halves
    if {$ob(random)} {
	set id1 [lrange $idirlist 0 $nslots2]
	incr nslots2
	set id2 [lrange $idirlist $nslots2 end]
	set idirlist {}
	lappend idirlist [shuffle $id1] [shuffle $id2]
	set idirlist [join $idirlist]
    }

    set ob(dirlist) {}
    foreach j $idirlist {
	lappend ob(dirlist) C $j
    }
}

proc fast_test_proc {} {
    global ob
    wshm no_safety_check 1
    wshm paused 0
    set ob(slottimeout) 2.0
    if {$ob(adaptive)} {
	set ob(vlim_wait) .5
	set ob(kvlim_wait) 500
	set ob(slottime) 1.0
	set ob(slottimeout) 3.0
    }
    puts "user hit Control-Alt-f, Fast Test Mode"
}

# do once at init.

proc onceg1 {} {
    global ob mob env

    # blink rate for target ball

    set ob(blinkrate) 0.5

    # set max log time 10 minutes
    set ob(logtimemax) 600000

    # set defaults, many of these will be overridden by the game_inits

    set ob(cur,x) 0.1
    set ob(cur,y) 0.1
    set ob(curcan,x) 0.1
    set ob(curcan,y) 0.1

    # control variables
    set ob(centerx) 0.0
    set ob(centery) -0.65
    set ob(damp) 5.0
    # set ob(stiff) 200.0
    set ob(Hz) 200

    set ob(curl) 0.0

    # which controller ID to use in movebox
    # planar
    set ob(controller) 0
    if {$ob(wrist)} {
	set ob(controller) 7
    } elseif {$ob(linear)} {
	set ob(controller) 16
    }

    set ob(linear_stiff) 0.0
    set ob(linear_damp) 0.0

    set ob(wrist_diff_damp) 0.0
    set ob(wrist_ps_damp) 0.0
    set ob(wrist_diff_stiff) 0.0
    set ob(wrist_ps_stiff) 0.0

    set ob(edge) 0
    set ob(edgedir) t
    set ob(slotpairnum) 1
    # default game type
    set ob(gametype) eval

    # how close to the centers do balls need to be for a hit?  in meters.
    # the on-screen balls are .025 cm in world space, so this is a bit
    # less than half-overlapped.
    set ob(hitradius) 0.010

    set ob(ball_size) .0125
    if {$ob(wrist)} {
	set ob(ball_size) [expr {$ob(ball_size) / $ob(wrist_scale)}]
	set ob(hitradius) [expr {$ob(hitradius) / $ob(wrist_scale)}]
    }
    set ob(cur_ball_size) [expr {$ob(ball_size) / 2.}]

    set ob(cursor_near_target) no

    set ob(halo_size) [expr {$ob(ball_size) * 3.0}]
    set ob(boom_size) [list $ob(ball_size) [expr {$ob(ball_size) * 10.0}]]

    # is this a "static" game? (user holds handle in center)
    set ob(static) no
    # is this a "dynamic" game? (program holds handle in center)
    set ob(dynamic) no
    # boom on ball enter?
    set ob(enter_boom) no
    # if noballhit is yes, then no events on ball hit
    set ob(noballhit) no

    # do processing for adaptive games
    set ob(adaptive) no

    # for "fake" adaptive long_tests, without metrics
    set ob(no_metrics) no

    # wrist ps game
    set ob(wrist_ps) no

    # wrist fe game
    set ob(wrist_fe) no

    # draw animals for kids
    set ob(draw_animals) no

    # draw images for 10-12 yo kids
    set ob(draw_1012) no

    set ob(adap_patient_moved) no
    set ob(collapse) no

    # grasp vars
    set ob(grasp_have) no
    set ob(grasp_games) no
    set ob(grasp_squeeze_game) no
    set ob(grasp_reach_game) no
    set ob(grasp_pick_game) no
    set ob(grasp_just_opened) no
    set ob(grasp_just_closed) no
    set ob(grasp_pick_first_approach) yes
    set ob(grasp_reach_first_approach) yes
    set ob(grasp_carrying_token) no
    set ob(grasp_squeeze_metric) no
    set ob(grasp_indicate) open
    set ob(next_squeeze_target_number) 0

    # planarhand flavor
    set ob(hand_pos) 0.050
    set ob(hand_stiff) 2400.0
    set ob(hand_damp) 20.0
    set ob(planarhand_grasp_games) no

    set ob(hand_collapse) yes

    # hide the score display
    set ob(hidescore) no

    # see note above enter_target_do_adaptive
    set ob(just_ran_pm_display) no

    # laser beam
    set ob(laser) no

    # orthogonal cursor scaling
    set ob(docurscale) no
    set ob(curscaleval) 1.

    # threshold for laser hit, meters
    set ob(laser_dist) 0.03

    set ob(sm_movebox) false

    # game description variables

    # are we logging?
    set ob(log) no
    # start_led
    set ob(start_led) no
    # how many vars to log during each sample
    # time x y vx vy
    # fx fy fz grasp
    set ob(logvars) 9
    # base directory for log files
    set ob(logdirbase) $::env(THERAPIST_HOME)
    # default log function
    set ob(logfnid) 0
    # shall we log each slot in its own file?
    set ob(logperslot) no
    # movebox state pre_wait, vlim_wait, etc.
    set ob(mb_state) paused
    # are we applying motor forces?
    set ob(motorforces) no
    # how many target balls on the clock edge?
    # (not the center or the cursor)
    set ob(nballs) 8
    # how many slot paths before we finish?
    set ob(nslots) 16
    # should the targets be chosen randomly (or sequentially)
    set ob(random) no
    # show cursor?
    set ob(showcursor) yes
    # distance in meters from center ball to edge ball (center to center)
    set ob(slotlength) 0.14
    # how long the movement should take, in seconds and ticks
    set ob(slottime) 1.4
    # slotticks in samples, fed to movebox
    set ob(slotticks) [expr {int($ob(slottime) * $ob(Hz))}]
    set ob(slotms) [expr {int($ob(slottime) * 1000)}]

    # how long to wait in seconds before "timing out" on a slot
    # time out sets to white-ball "paused" mode
    set ob(slottimeout) 0.0
    # should we pause when a slot times out?
    set ob(timeoutpause) no

    # for circle eval games
    set ob(smallercircle) no
    # for shouler eval games
    set ob(shoulderarrow) no
    set ob(shoulderarrowdir) up
    set ob(forcearrowx) 0.0

    # for 4-way games
    set ob(proto_dirs4x) no
    set ob(proto_dirs4+) no

    # fan game
    set ob(nfan) no
    set ob(sfan) no
    set ob(efan) no
    set ob(wfan) no

    set ob(proto_change_target) no
    set ob(randedge) no
    set ob(change_pct) 10
    set ob(change_time) .5

    # center the arm with motor force, unless we ask not to.
    set ob(nocenterarm) no

    set ob(pre_wait) 0.0
    set ob(vlim_wait) 0.0

    set ob(dobeep) no

    # file names built from current time.  current time is taken once
    # here, so that all files for a run have the same time, which is
    # convenient for grouping them.

    set curtime [clock seconds]
    set ob(datestamp) [clock format $curtime -format "%Y%m%d_%a"]
    set ob(timestamp) [clock format $curtime -format "%H%M%S"]
    # set ob(dirname) [file join $ob(logdirbase) $ob(patname)
      # $ob(gametype) $ob(datestamp) ]

    # blinking ball colors
    set ob(ball,col,1) red
    set ob(ball,col,2) orange

    # compass directions
    set ob(dirs)    { N NE  E SE  S SW  W NW }

    # 4 way dir protocols
    set ob(dirs4+)    { N E S W }
    set ob(dirs4x)    { NE SE SW NW }
    set ob(dirsnfan)   { N NW W NW N NE E NE }
    set ob(dirssfan)   { S SW W SW S SE E SE }
    set ob(dirsefan)   { N NE E SE S SE E NE }
    set ob(dirswfan)   { N NW W SW S SW W NW }

    # this may be overrridden by read_game_init
    set ob(dirnums) { 0  1  2  3  4  5  6  7 }

    set ob(dopath) 0
    set ob(dopathi) 0

    # which you hit the "Alt-m" key, you get a menu with various info
    # may be useful in a clinical setting, or not.
    # off by default.  toggles on and off.

    set m [menu_init .menu]

    # build the menu.
    # the menu building procs are:
    # menu_t label text
    # menu_cb checkbox
    # menu_v variable entry
    # menu_b button

    menu_t $m hits Hits
    menu_t $m hittime Time
    menu_t $m avgtime Avg Time
    menu_t $m blank2 "" ""
    # menu_cb $m random Random
    set mob(random) no
    menu_t $m blank3 "" ""
    menu_v $m increment Increment
    # menu_v $m nballs Spots
    menu_v $m thresh Threshold
    menu_t $m blank4 "" ""
    menu_b $m restart "New Game (n)" restartg1
    menu_t $m menu "Toggle Menu (Alt-m)" ""
    menu_b $m quit "Exit (q)" {clock_exit}

    # display scale
    # 2000.0 means 1 meter on the table == 2000 pixels on the screen.
    # .14m == 280 pixels
    # for planar
    # set ob(scale) [expr 250. / 0.14] == 1785
    # orginally, set ob(scale) 1800.0
    # for wrist, 1800 * 14 / 26
    set ob(scale) 2200.
    if {$ob(wrist)} {
        set ob(scale) [expr {$ob(scale) * $ob(wrist_scale)}]
    }
    if {$ob(linear)} {
        set ob(scale) [expr {250 / 0.14 * 4 / 3}]
    }

    # array size for rolling average
    set ob(avn) 10

    # not blinking yet.
    set ob(blinking) no

    # bind . binds the big window
    # new window, quit
    # bind . <n> restartg1
    bind . <a> print_afters
    bind . <c> change_contrast
    bind . <m> print_pm
    bind . <x> toggle_sm_movebox
    bind . <b> toggle_beep
    bind . <f> clock_ft_dobias
    bind . <i> draw_new_images
    bind . <o> dump_ob
    bind . <p> do_path
    bind . <q> clock_exit
    bind . <Q> clock_exit
    bind . <Escape> clock_exit
    # toggle start/stop.  target blinks when started.
    # white when stopped.
    bind . <space> clock_space

    # we don't want people hitting these two by mistake,
    # so make them control-alt

    # simulate a slot timeout, for testing
    bind . <Control-Alt-c> {
	puts "user hit Control-Alt-c, cancel slot timeout now."
	after cancel do_slot_timeout
	cancel_mb_timeouts
	do_slot_timeout
    }

    # fast test proc, for testing
    bind . <Control-Alt-f> {fast_test_proc}

    # unbind the Alt-m menu, we don't want people playing with menus here.
    bind . <Alt-m> {puts "There is no clock task menu."}

    wm protocol . WM_DELETE_WINDOW { clock_exit }
    # dump game variables to stdout, for debugging.

    # bind .menu binds the menu window
    # bind .menu <n> restartg1
    bind .menu <q> clock_exit
    bind .menu <Escape> clock_exit
    # bind .menu <space> clock_space

    # useful for measurement/debugging.
    # note that cur,x/y will not be updated when "no_arm" is called.
    # 1st two are ball cursor in world space,
    # 2nd two are X cursor in screen space
    # bind . <Motion> [list wm title . "cursor pos $ob(cur,x) $ob(cur,y) $ob(curcan,x) $ob(curcan,y) %x %y"]

    # this is useful for debugging measurement and cursor placement

    # it's bad for people to lean on the space bar, so repeat
    no_kbd_repeat
    start_lkm
    start_shm

    # for now, bias ft at beginning of each game
    after 200 {clock_ft_dobias}

    ### read game control file here
    ### to override defaults, and apply some vars to shared memory

    read_game_init $ob(gamename)

    # in most cases, it will be set in the game init files,
    # but allow override here.
    set ob(logdirbase) $::env(THERAPIST_HOME)

    apply_init_vars

    # this needs slotlength.
    hand_set_points

    set ob(dirname) [file join $ob(logdirbase) $ob(patname) \
      $ob(gametype) $ob(datestamp) ]

    # settable text variables, these are deprecated.
    set mob(increment) 1
    set mob(random) $ob(random)
    set mob(nballs) 8

    # this is the green/red threshold in ms.  0 is off.
    set mob(thresh) 0

    # counters
    set mob(hits) 0
    set ob(slotnum) 1
    set mob(hittime) 0
    set mob(avgtime) 0

    if {$ob(adaptive)} {
	init_adap
    }

    # unpause the robot control loop LKM
    start_loop
    after 100
}

# write pathlength tag /tmp/clock/pathlen.pid, which will be
# used by start_log, so that reach_error knows whether we're 10 or 14 cm.

proc tag_slotlength {} {
    global ob

    set ob(pathlenfilename) "/tmp/clock_path/pathlen.[pid]"
    file mkdir "/tmp/clock_path/"
    exec /bin/echo s pathlength $ob(slotlength) > $ob(pathlenfilename)
    # this gets deleted in clock_exit
}

# restart the game
# reset vars, calculate some positions

proc restartg1 {} {
    global ob mob

    # not first time through.
    if {[winfo exists .fl]} {
	destroy .fl
    }

    # if there are any slots running, stop them
    # TODO: check these, probably want to stop all outstanding moveboxes.
    stop_movebox 0

    set ob(random) $mob(random)
    set ob(increment) $mob(increment)

    set mob(hits) 0
    set ob(slotnum) 1
    set mob(hittime) 0
    set mob(avgtime) 0

    set ob(t0) [clockms]
    set ob(avi) 0
    set ob(avgtime) 0
    for {set i 0} {$i < $ob(avn)} {incr i} {
	set ob(avg,$i) 0
    }

    # found empirically on 1024x768 screen under gnome
    # the size of the window on screen
    # wm geom . 1009x738+0+0

    wm attributes . -zoomed 1
    update idletasks

    # inner radius world space (with the balls centered on it).
    set ob(irad) $ob(slotlength)
    # outer radius (the enclosing circle)
    set ob(orad) [expr {16./14. * $ob(slotlength)}]

    # set up direction list
    dodirlist

    # .fl - originally the left frame, when the menu was the right frame.
    # has the status line .fl.status on the bottom,
    # and setupg1 sets up the big clock canvas in .fl too.

    frame .fl
    pack .fl -fill both -expand true

    if {$ob(linear)} {
	set w [setupglinear .fl.c]
    } elseif {$ob(wrist) && $ob(wrist_ps)
	&& ($ob(draw_animals) || $ob(draw_1012))} {
	set w [setupghoriz2 .fl.c]
    } elseif {$ob(wrist) && $ob(wrist_fe)
	&& ($ob(draw_animals) || $ob(draw_1012))} {
	set w [setupghoriz2 .fl.c]
    } elseif {$ob(wrist) && $ob(wrist_ps)} {
	set w [setupghoriz .fl.c]
    } elseif {$ob(wrist) && $ob(wrist_fe)} {
	set w [setupghoriz .fl.c]
    } else {
	if {$ob(draw_animals) || $ob(draw_1012)} {
	    set w [setupg2 .fl.c]
	} else {
	    set w [setupg1 .fl.c]
	}
    }
    # grid $w
    pack $w
    set ob(bigcan) $w

    label .fl.status -textvariable ob(status) -font default\
      -background gray20 -foreground gray50
    pack .fl.status -fill x
    status_mes [imes "Press Space Bar to Start"]

    # experiment...
    if {[winfo exists .disp]} {
	destroy .disp
    }
    set ob(score) "$mob(hits)/$ob(nslots)"
    label .disp -textvariable ob(score)  -font $ob(scorefont) -bg gray25 -fg yellow
    place .disp -in . -relx 1.0 -rely 0.0 -anchor ne

    # puts "window size $ob(can,x) $ob(can,y)"

    if {$ob(grasp_games)} {
	clock_init_grasp
    }

    # do final initialization of game vars
    gameinit $w

    if {$ob(laser)} {
	set ob(laser_score) 0
	label .laserdisp -textvariable ob(laser_score)  -font $ob(scorefont) -bg gray25 -fg green1
	place .laserdisp -in . -relx 0.0 -rely 0.0 -anchor nw
    }

    if {$ob(grasp_pick_game)} {
	set ob(grasp_score) 0
	set ob(grasp_score_str) 0/0
	label .graspdisp -textvariable ob(grasp_score_str) -font $ob(scorefont) -bg gray25 -fg green1
	place .graspdisp -in . -relx 0.0 -rely 0.0 -anchor nw
    }

    tag_slotlength

    # event loop to handle things that move and blink
    xyinit $w
}

# animal images are from
# http://www.hasslefreeclipart.com/kid_animals/page1.html
# used under terms:
# http://www.hasslefreeclipart.com/pages_terms.html

proc odraw_animals {w} {
    global ob

    set alist {cow chick camel koala fish lion giraffe frog}
    foreach an $alist dir $ob(dirs) {
	foreach {x y} $ob(ball,$dir,center) break
	set x [expr {$x * $ob(scale)}]
	set y [expr {$y * $ob(scale)}]
	set img($an,im) [image create photo -file images/animals/animals_$an.gif]
	set img($an,id) [$w create image $x $y -image $img($an,im) \
	    -tag timage -anchor center]
    }
    $w raise ball
    $w raise halo
}

proc draw_new_images {} {
    global ob

    set w $ob(bigcan)
    if {$ob(draw_animals)} {
	draw_animals $w
    }
    if {$ob(draw_1012)} {
	draw_1012 $w
    }
    $w raise ball
    $w raise halo
    $w raise grasp_reach_ring
    $w raise cursor
    $w raise laser
    $w raise boom
}

proc draw_animals {w} {
    global ob

    set ob(pic,basedir) [file join $::env(IMAGES_HOME) clock ku10]

    foreach d [glob -join $ob(pic,basedir) *] {
	lappend uilist [file rootname [file tail $d]]
    }
    set uilist [lsort $uilist]

    # shuffle sorted list
    set ilistlast [llength $ob(dirs)]
    incr ilistlast -1
    set ilist [lrange [shuffle $uilist] 0 $ilistlast]

    $w delete image -tag timage
    foreach i $ilist dir $ob(dirs) {
	foreach {x y} $ob(ball,$dir,center) break
	set x [expr {$x * $ob(scale)}]
	set y [expr {$y * $ob(scale)}]
	set img($i,im) [image create photo -file [glob $ob(pic,basedir)/$i.gif]]
	set img($i,id) [$w create image $x $y -image $img($i,im) \
	    -tag timage -anchor center]
    }
    $w raise ball
    $w raise halo
}


# grasp game

proc clock_init_grasp {} {
    global ob

    set w $ob(bigcan)

    set ob(grasp_state) "open"
    set ob(grasp_volts) 0.0

    set ob(grasp_token,x) 0.0
    set ob(grasp_token,y) 0.0

    start_grasp

    set ob(grasp_squeeze_count) 0
    set ob(grasp_release_count) 0

    if {$ob(grasp_pick_game)} {
	set ob(grasp_token_size) [expr {$ob(ball_size) * 2}]
	set token [$w create oval [centxy 0 0 $ob(grasp_token_size)] -fill blue1 \
	    -width 2 -outline yellow -tags {grasp_token grasp}]
# dtime "grasp_token $token"
	# canvas bind doesn't work here
	bind $w <<GraspPress>> {grasp_pick_game_press %x %y %W}
	bind $w <<GraspRelease>> {grasp_pick_game_release %x %y %W}
	bind $w <<GraspMotion>> {grasp_pick_game_motion %x %y %W}
        $w raise ball
        $w raise cursor
    }

    if {$ob(grasp_reach_game)} {
	bind $w <<GraspPress>> {grasp_reach_game_press %x %y %W}
	bind $w <<GraspRelease>> {grasp_reach_game_release %x %y %W}
	set ob(grasp_reach_ring_size) $ob(ball_size)
	set reach_ring [$w create oval [centxy 0 0 $ob(grasp_reach_ring_size)] \
	    -width 10 -outline green1 -tags {grasp_reach_ring grasp} -state hidden]
        $w raise cursor
    }

    if {$ob(grasp_squeeze_game)} {
	set ob(grasp_squeeze_small) $ob(ball_size)
	set ob(grasp_squeeze_big) $ob(orad)

	$w create oval [centxy 0 0 $ob(grasp_squeeze_small)] -outline $ob(ball,col,1) -width 10 \
	    -tags {grasp_squeeze_target grasp} -state hidden
	$w create oval [centxy 0 0 $ob(grasp_squeeze_big)] -outline yellow -width 3 \
	    -dash {5 40} -tags {grasp_squeeze_cursor grasp} -state hidden
	bind $w <<GraspPress>> {grasp_squeeze_game_press %x %y %W}
	bind $w <<GraspRelease>> {grasp_squeeze_game_release %x %y %W}
    }
    $w scale grasp 0 0 $ob(scale) -$ob(scale)

    ctinit hand_ap_in -lastn 80
    ctinit hand_ap_out -lastn 80
}

# based on
# Example 34-2 Welch's PP TclTk book
# The canvas "Hello, World!" example.

# used only in grasp pick game

proc grasp_mark {x y can} {
    global drag ob
# dtime "called grasp_mark $x $y $can"

    # Map from view coordinates to canvas coordinates
    set x [$can canvasx $x]
    set y [$can canvasy $y]
    # Remember the object and its location

    # only grab the grasp_token
    set got_token no
    foreach obj [$can find overlapping $x $y $x $y] {
	if {$obj == [$can find withtag grasp_token]} {
	    set got_token yes
	    break
	}
    }
    if {!$got_token} {
	grasp_clear_drag_state
	return
    }

    # center the grasp_token at the current cursor
    set w $ob(bigcan)
    $w coords grasp_token [centxy $ob(cur,x) $ob(cur,y) $ob(grasp_token_size)]
    $w scale grasp_token 0 0 $ob(scale) -$ob(scale)

    set drag($can,obj) $obj
    set drag($can,x) $x
    set drag($can,y) $y

    set ob(grasp_token,x) [expr {$x / $ob(scale)}]
    set ob(grasp_token,y) [expr {$y / -$ob(scale)}]
}

proc grasp_drag {x y can} {
    global drag ob
# dtime "called grasp_drag $x $y $can"

    if {![array exists drag]} return

    # Map from view coordinates to canvas coordinates
    set x [$can canvasx $x]
    set y [$can canvasy $y]
    # Move the current object
    set dx [expr {$x - $drag($can,x)}]
    set dy [expr {$y - $drag($can,y)}]
    $can move $drag($can,obj) $dx $dy
    set drag($can,x) $x
    set drag($can,y) $y
    set ob(grasp_token,x) [expr {$x / $ob(scale)}]
    set ob(grasp_token,y) [expr {$y / -$ob(scale)}]
}

# images are from
# http://www.hasslefreeclipart.com/kid_animals/page1.html
# used under terms:
# http://www.hasslefreeclipart.com/pages_terms.html

proc draw_1012 {w} {
    global ob

    set ob(pic,basedir) [file join $::env(IMAGES_HOME) clock k1012]

    foreach d [glob -join $ob(pic,basedir) *] {
	lappend uilist [file rootname [file tail $d]]
    }
    set uilist [lsort $uilist]

    # shuffle sorted list
    set ilistlast [llength $ob(dirs)]
    incr ilistlast -1
    set ilist [lrange [shuffle $uilist] 0 $ilistlast]

    $w delete image -tag timage
    foreach i $ilist dir $ob(dirs) {
	foreach {x y} $ob(ball,$dir,center) break
	set x [expr {$x * $ob(scale)}]
	set y [expr {$y * $ob(scale)}]
	set img($i,im) [image create photo -file [glob $ob(pic,basedir)/$i.gif]]
	set img($i,id) [$w create image $x $y -image $img($i,im) \
	    -tag timage -anchor center]
    }
    $w raise ball
    $w raise halo
}

proc setup_can {w} {
    global ob

    set ob(bigcan) $w
    # the size of the canvas in the window
    set ob(can,x) [winfo width $ob(bigcan)]
    set ob(can,y) [winfo height $ob(bigcan)]

    # center of window in pixels
    set ob(half,x) [expr {$ob(can,x) / 2.}]
    set ob(half,y) [expr {$ob(can,y) / 2.}]
}

# do the actual canvas munging

proc setupg1 {w} {
    global ob

    # create a canvas, $w this will be ob(bigcan)
    set w [canvas $w -bg gray25]
    # the edge highlight of the canvas should be 0 width
    # this is important for the math that converts robot x/y to screen x/y
    $w configure -highlightthickness 0

    pack $w -fill both -expand true
    update idletasks

    setup_can $w

    # the window outside the canvas
    . configure -background gray25

    # make the center be 0,0 - translate by "scrolling"
    $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x)\
      $ob(half,y)]

    # draw big filled circle
    $w create oval [centxy 0 0 $ob(orad)] -fill gray25 -width 5 -tag bigcircle

    # draw eight (or whatever) nballs, in a loop.
    # nballs should now be fixed to 8.
    set col1 navyblue
    set col2 blue

    set pi [expr {acos(0.) * 2.}]

    # if there are 8 slices, each slice is 360/9 degrees.
    set extdeg [expr {360 /($ob(nballs) + 1)}]
    for {set i 0} {$i < $ob(nballs)} {incr i} {
	set ideg [expr {$i * 360 / $ob(nballs)}]
	set i2 [expr {$ideg - $extdeg / 2}]
	# outer circle
	eval $w create arc [centxy 0 0 $ob(orad)] -start $i2 -extent $extdeg\
	  -style pieslice -fill $col1 -width 3 -tag outer

	# inner circle
	eval $w create arc [centxy 0 0 $ob(irad)] -start $i2 -extent $extdeg\
	  -style pieslice -fill $col2 -width 3 -tag inner
    }

    # draw a ball in the center, then balls on edge.

    # call it C for center.
    set ob(ball,C,dir) C

    # world position of center of the ball for movebox, x,y
    set ob(ball,C,center) {0.0 0.0}
    # canvas object id, returned by canvas create
    set ob(ball,C,id) [$w create oval [centxy 0.0 0.0 $ob(ball_size)] \
	 -fill black -tag [list ball C]]
    # ball dir from id, N, NE, etc, and C for center.
    set ob(ball,$ob(ball,C,id),dir) $ob(ball,C,dir)

    # draw balls at circumference, all tagged as balls.
    # starting at top, going clockwise

    # irad is radius of inner circle
    set rad $ob(irad)
    for {set i 0} {$i < $ob(nballs)} {incr i} {
	# use trig to calculate positions
	set sx [expr {sin(($i * $pi / $ob(nballs) * 2))}]
	set sy [expr {cos(($i * $pi / $ob(nballs) * 2))}]

	set cx [expr {($rad * $sx)}]
	set cy [expr {($rad * $sy)}]

	# see comments for center ball above
	set dir [lindex $ob(dirs) $i]
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-fill black -tag [list ball $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir
    }

    # create cursor off center
    # will soon be at actual cursor position after pointer motion
    set ob(cursor,id) [$w create oval [centxy .1 .1 $ob(cur_ball_size)] \
	-tag cursor -fill yellow]
    set ob(laser,id) [$w create line {.1 .1 .1 .1} \
        -arrow last -tag laser -fill green1 -width 5]

    # to hide mouse pointer:
    # $w itemconfig cursor -state hidden

    # scale the canvas, and flip y
    $w scale all 0 0 $ob(scale) -$ob(scale)

    $w raise cursor

    # return the widget ID of the canvas
    return $w
}

proc setupglinear {w} {
    global ob

    # create a canvas, $w this will be ob(bigcan)
    set w [canvas $w -bg gray25]
    # the edge highlight of the canvas should be 0 width
    # this is important for the math that converts robot x/y to screen x/y
    $w config -highlightthickness 0

    pack $w -fill both -expand true
    update idletasks

    setup_can $w

    # the window outside the canvas
    . configure -background gray25

    # make the center be 0,0 - translate by "scrolling"
    $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x)\
      $ob(half,y)]

    set col1 navyblue
    set col2 blue

    set sl $ob(slotlength)
    set osl [expr {$ob(slotlength) + .025}]

    eval $w create rect -.05 -$osl .05 $osl \
	-fill $col1 -width 3 -tag outer

    eval $w create rect -.025 -$sl .025 $sl \
	-fill $col2 -width 3 -tag inner

    # draw a ball in the center, then balls in column

    # call it C for center.
    set ob(ball,C,dir) C

    # world position of center of the ball for movebox, x,y
    set ob(ball,C,center) {0.0 0.0}
    # canvas object id, returned by canvas create
    set ob(ball,C,id) [$w create oval [centxy 0.0 0.0 $ob(ball_size)] \
	 -fill black -tag [list ball C]]
    # ball dir from id, N, S, and C for center.
    set ob(ball,$ob(ball,C,id),dir) $ob(ball,C,dir)

    # draw balls in column, all tagged as balls.

    # what are the units here?
    set spacing $ob(slotlength)

	set cx 0.0
	set cy $spacing

	# see comments for center ball above
	# N ball
	set dir N
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-fill black -tag [list ball $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

	# see comments for center ball above
	# S ball
	set cy -$cy
	set dir S
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-fill black -tag [list ball $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

    # create cursor off center
    # will soon be at actual cursor position after pointer motion
    set ob(cursor,id) [$w create oval [centxy .1 .1 $ob(cur_ball_size)] -tag cursor\
      -fill yellow]

    # to hide mouse pointer:
    # $w itemconfig cursor -state hidden

    # scale the canvas, and flip y
    $w scale all 0 0 $ob(scale) -$ob(scale)

    # return the widget ID of the canvas
    return $w
}

# horizontal, for wrist ps, and maybe linear?

proc setupghoriz {w} {
    global ob

    # create a canvas, $w this will be ob(bigcan)
    set w [canvas $w -bg gray25]
    # the edge highlight of the canvas should be 0 width
    # this is important for the math that converts robot x/y to screen x/y
    $w configure -highlightthickness 0

    pack $w -fill both -expand true
    update idletasks

    setup_can $w

    # the window outside the canvas
    . configure -background gray25

    # make the center be 0,0 - translate by "scrolling"
    $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x)\
      $ob(half,y)]

    set col1 navyblue
    set col2 blue

    eval $w create rect -.4 -.1 .4 .1 \
	-fill $col1 -width 3 -tag outer

    eval $w create rect -.3 -.05 .3 .05 \
	-fill $col2 -width 3 -tag inner

    # draw a ball in the center, then balls in row

    # call it C for center.
    set ob(ball,C,dir) C

    # world position of center of the ball for movebox, x,y
    set ob(ball,C,center) {0.0 0.0}
    # canvas object id, returned by canvas create
    set ob(ball,C,id) [$w create oval [centxy 0.0 0.0 $ob(ball_size)] \
	 -fill black -tag [list ball C]]
    # ball dir from id, W, E, etc, and C for center.
    set ob(ball,$ob(ball,C,id),dir) $ob(ball,C,dir)

    # draw balls in row, all tagged as balls.
    # W C E

    # what are the units here?
    set spacing .15

    for {set i 1} {$i <= $ob(nballs) / 2} {incr i} {
	set cx [expr {($ob(nballs) * $spacing * $i)}]
	set cy 0.0

	# see comments for center ball above
	# right ball E +x
	set dir E
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-fill black -tag [list ball $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

	# see comments for center ball above
	# left ball W -x
	set cx -$cx
	set dir W
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-fill black -tag [list ball $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

    }

    # create cursor off center
    # will soon be at actual cursor position after pointer motion
    set ob(cursor,id) [$w create oval [centxy .1 .1 $ob(cur_ball_size)] -tag cursor\
      -fill yellow]

    # to hide mouse pointer:
    # $w itemconfig cursor -state hidden

    # scale the canvas, and flip y
    $w scale all 0 0 $ob(scale) -$ob(scale)

    # return the widget ID of the canvas
    return $w
}

# horizontal, for wrist ps, and maybe linear?

proc setupghoriz2 {w} {
    global ob

    # create a canvas, $w this will be ob(bigcan)
    set w [canvas $w -bg gray25]
    # the edge highlight of the canvas should be 0 width
    # this is important for the math that converts robot x/y to screen x/y
    $w configure -highlightthickness 0

    pack $w -fill both -expand true
    update idletasks

    setup_can $w

    # the window outside the canvas
    . configure -background gray25

    # make the center be 0,0 - translate by "scrolling"
    $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x)\
      $ob(half,y)]

    # draw the horizontal bar
    # set col1 navyblue
    # set col2 blue

    # eval $w create rect -.4 -.1 .4 .1 \
	# -fill $col1 -width 3 -tag outer

    # eval $w create rect -.3 -.05 .3 .05 \
	# -fill $col2 -width 3 -tag inner

    # draw a ball in the center, then balls in row

    # call it C for center.
    set ob(ball,C,dir) C

    # world position of center of the ball for movebox, x,y
    set ob(ball,C,center) {0.0 0.0}
    # canvas object id, returned by canvas create
    set ob(ball,C,id) [$w create oval [centxy 0.0 0.0 $ob(ball_size)] \
	 -outline black -width 0 -tag [list ball C]]
    set ob(halo,C,id) [$w create oval [centxy 0.0 0.0 $ob(halo_size)] \
	 -outline black -width 0 -tag [list ball halo C]]
    # ball dir from id, W, E, etc, and C for center.
    set ob(ball,$ob(ball,C,id),dir) $ob(ball,C,dir)

    set pos [list 0.0 0.0]
    set size $ob(boom_size)
    set rot [random 0 360]
    set n   [random 5 15]
    set col yellow
    set boom [star $pos $size $rot $n]

    set ob(boom,C,id) [$w create poly $boom -outline black \
        -width 1 -fill $col -tag [list boom boom_C] -state hidden]

    # draw balls in row, all tagged as balls.
    # W C E

    # what are the units here?
    set spacing .15

    for {set i 1} {$i <= $ob(nballs) / 2} {incr i} {
	set cx [expr {($ob(nballs) * $spacing * $i)}]
	set cy 0.0

	# see comments for center ball above
	# right ball E +x
	set dir E
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-outline black -tag [list ball $dir]]
	set ob(halo,$dir,id) [$w create oval [centxy $cx $cy $ob(halo_size)] \
		-outline black -tag [list ball halo $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

        set pos [list $cx $cy]
        set size $ob(boom_size)
        set rot [random 0 360]
        set n   [random 10 15]
        set col yellow
        set boom [star $pos $size $rot $n]

        set ob(boom,$dir,id) [$w create poly $boom -outline black \
            -width 1 -fill $col -tag [list boom boom_$dir] -state hidden]

	# see comments for center ball above
	# left ball W -x
	set cx -$cx
	set dir W
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-outline black -tag [list ball $dir]]
	set ob(halo,$dir,id) [$w create oval [centxy $cx $cy $ob(halo_size)] \
		-outline black -tag [list ball halo $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

        set pos [list $cx $cy]
        set size $ob(boom_size)
        set rot [random 0 360]
        set n   [random 10 15]
        set col yellow
        set boom [star $pos $size $rot $n]

        set ob(boom,$dir,id) [$w create poly $boom -outline black \
            -width 1 -fill $col -tag [list boom boom_$dir] -state hidden]

        set pos [list $cx $cy]
        set size $ob(boom_size)
        set rot [random 0 360]
        set n   [random 10 15]
        set col yellow
        set boom [star $pos $size $rot $n]

        set ob(boom,$dir,id) [$w create poly $boom -outline black \
            -width 1 -fill $col -tag [list boom boom_$dir] -state hidden]

        set pos [list $cx $cy]
        set size $ob(boom_size)
        set rot [random 0 360]
        set n   [random 10 15]
        set col yellow
        set boom [star $pos $size $rot $n]

        set ob(boom,$dir,id) [$w create poly $boom -outline black \
            -width 1 -fill $col -tag [list boom boom_$dir] -state hidden]
    }

    # create cursor off center
    # will soon be at actual cursor position after pointer motion
    set ob(cursor,id) [$w create oval [centxy .1 .1 $ob(cur_ball_size)] -tag cursor\
      -fill yellow]

    # to hide mouse pointer:
    # $w itemconfig cursor -state hidden

    # scale the canvas, and flip y
    $w scale all 0 0 $ob(scale) -$ob(scale)

    if {$ob(draw_animals)} {
        draw_animals $w
    }

    if {$ob(draw_1012)} {
        draw_1012 $w
    }

    # oops, this isn't set up yet..
    set ob(bigcan) $w

    color_ball off ball
    $w raise cursor
    $w raise laser
    $w raise boom

    # return the widget ID of the canvas
    return $w
}

proc setupg2 {w} {
    global ob

    # create a canvas, $w this will be ob(bigcan)
    set w [canvas $w -bg gray25]
    # the edge highlight of the canvas should be 0 width
    # this is important for the math that converts robot x/y to screen x/y
    $w configure -highlightthickness 0

    pack $w -fill both -expand true
    update idletasks

    setup_can $w

    # the window outside the canvas
    . configure -background gray25

    # make the center be 0,0 - translate by "scrolling"
    $w config -scrollregion [list -$ob(half,x) -$ob(half,y) $ob(half,x)\
      $ob(half,y)]

    # draw big filled circle
    # $w create oval [centxy 0 0 $ob(orad)] -fill gray25 -width 3 -tag bigcircle

    # draw eight (or whatever) nballs, in a loop.
    # nballs should now be fixed to 8.
    # set col1 navyblue
    # set col2 blue

    set pi [expr {acos(0.) * 2.}]

    # draw a ball in the center, then balls on edge.

    # call it C for center.
    set ob(ball,C,dir) C

    # world position of center of the ball for movebox, x,y
    set ob(ball,C,center) {0.0 0.0}
    # canvas object id, returned by canvas create
    set ob(ball,C,id) [$w create oval [centxy 0.0 0.0 $ob(ball_size)] \
	 -outline black -width 0 -tag [list ball C]]
    set ob(halo,C,id) [$w create oval [centxy 0.0 0.0 $ob(halo_size)] \
	 -outline black -width 0 -tag [list ball halo C]]
    # ball dir from id, N, NE, etc, and C for center.
    set ob(ball,$ob(ball,C,id),dir) $ob(ball,C,dir)


    set pos [list 0.0 0.0]
    set size $ob(boom_size)
    set rot [random 0 360]
    set n   [random 5 15]
    set col yellow
    set boom [star $pos $size $rot $n]

    set ob(boom,C,id) [$w create poly $boom -outline black \
	-width 1 -fill $col -tag [list boom boom_C] -state hidden]

    # draw balls at circumference, all tagged as balls.
    # starting at top, going clockwise

    # irad is radius of inner circle
    set rad $ob(irad)
    for {set i 0} {$i < $ob(nballs)} {incr i} {
	# use trig to calculate positions
	set sx [expr {sin(($i * $pi / $ob(nballs) * 2))}]
	set sy [expr {cos(($i * $pi / $ob(nballs) * 2))}]

	set cx [expr {($rad * $sx)}]
	set cy [expr {($rad * $sy)}]

	# see comments for center ball above
	set dir [lindex $ob(dirs) $i]
	set ob(ball,$dir,center) [list $cx $cy]
	set ob(ball,$dir,id) [$w create oval [centxy $cx $cy $ob(ball_size)] \
		-outline black -width 0 -tag [list ball $dir]]
	set ob(halo,$dir,id) [$w create oval [centxy $cx $cy $ob(halo_size)] \
		-outline black -width 0 -tag [list ball halo $dir]]
	set ob(ball,$ob(ball,$dir,id),dir) $dir

	set pos [list $cx $cy]
	set size $ob(boom_size)
	set rot [random 0 360]
	set n   [random 10 15]
	set col yellow
	set boom [star $pos $size $rot $n]

	set ob(boom,$dir,id) [$w create poly $boom -outline black \
	    -width 1 -fill $col -tag [list boom boom_$dir] -state hidden]

    }

    # create cursor off center
    # will soon be at actual cursor position after pointer motion
    set ob(cursor,id) [$w create oval [centxy .1 .1 $ob(cur_ball_size)] -tag cursor\
      -fill yellow]
    set ob(laser,id) [$w create line {.1 .1 .1 .1} \
	-arrow last -tag laser -fill green1 -width 5]

    # set ob(laser,id) [$w create oval [centxy .05 .05 $ob(halo_size)] -tag laser -fill green1]
# dtime "laser: centxy .05 .05 $ob(halo_size)"

    # to hide mouse pointer:
    # $w itemconfig cursor -state hidden

    # scale the canvas, and flip y
    $w scale all 0 0 $ob(scale) -$ob(scale)

    if {$ob(draw_animals)} {
	draw_animals $w
    }

    if {$ob(draw_1012)} {
	draw_1012 $w
    }

    # oops, this isn't set up yet..
    set ob(bigcan) $w

    color_ball off ball
    $w raise cursor
    $w raise laser
    $w raise boom

    # return the widget ID of the canvas
    return $w
}

# show indictator arrows for circle games

proc circlearrow {w} {
    global ob mob

    set smallrad [expr {$ob(orad) / 2.0}]

    switch -- $ob(circlestart) {
    9cw {
	set x1 [expr {0.0 - $smallrad}]
	set y1 0.0
	set x2 [expr {0.0 - $smallrad + .01}]
	set y2 .04
    }
    9ccw {
	set x1 [expr {0.0 - $smallrad}]
	set y1 0.0
	set x2 [expr {0.0 - $smallrad + .01}]
	set y2 -.04
    }
    3cw {
	set x1 [expr {$smallrad}]
	set y1 0.0
	set x2 [expr {$smallrad - .01}]
	set y2 -.04
    }
    3ccw {
	set x1 [expr {$smallrad}]
	set y1 0.0
	set x2 [expr {$smallrad - .01}]
	set y2 .04
    }
    default return
    }

    $w create line $x1 $y1 $x2 $y2 \
	    -arrow last -arrowshape {15 20 10} \
	    -width 10 -fill orange -tag dirarrow
    $w scale dirarrow 0 0 $ob(scale) -$ob(scale)

    $w raise cursor
}

# show indicator arrows for shoulder games

proc shoulderarrow {w} {
    global ob

    set smallrad [expr {0 - $ob(orad) / 2.0}]

    set x1 $smallrad
    set y1 0.0
    set x2 $smallrad

    if {[string equal $ob(shoulderarrowdir) "up"]} {
	set y2 0.04
    } else {
	set y2 -0.04
    }

    $w create line $x1 $y1 $x2 $y2 \
	    -arrow last -arrowshape {15 20 10} \
	    -width 10 -fill orange -tag dirarrow
    $w scale dirarrow 0 0 $ob(scale) -$ob(scale)

    set ob(forcearrowx) [expr {$ob(slotlength) * -1.5}]

    set x1 $ob(forcearrowx)
    set y1 0.0
    set x2 $ob(forcearrowx)
    set y2 0.1

    $w create line $x1 $y1 $x2 $y2 \
	    -arrow last -arrowshape {15 20 10} \
	    -width 10 -fill green1 -tag forcearrow
    $w scale forcearrow 0 0 $ob(scale) -$ob(scale)

    label .fdisp -text "Too much force!" -font $ob(scorefont) -bg gray25 -fg red
    place .fdisp -in . -relx 0.0 -rely 0.0 -anchor nw
    place forget .fdisp

    $w raise cursor
}

# final init before starting game

proc gameinit {w} {
    global ob mob

    if {$ob(smallercircle)} {
	set smallrad [expr {$ob(orad) / 2.0}]
	$w coords bigcircle [centxy 0 0 $smallrad]
	$w scale bigcircle 0 0 $ob(scale) -$ob(scale)

	circlearrow $w
    }

    if {$ob(shoulderarrow)} {
	shoulderarrow $w
    }

    # blink counter
    set ob(blinki) 0

    # if a blink loop already exists, cancel it.
    after cancel blinkloop $w

    # center the hand (open) even when you're not centering the others.
    if {$ob(planarhand_grasp_games)} {
	hand_grasp_center
    }

    if {!$ob(nocenterarm)} {
	# move the arm from its current position to world origin
	center_arm
    }

    # if you want to hide the score display
    if {$ob(hidescore)} {
	lower .disp
    }

    set mob(hits) 0
    set ob(slotnum) 1
    init_target

    if {!$ob(showcursor)} {
	$ob(bigcan) itemconfig cursor -state hidden
    }
}

# cancel blink loop and stop blinking
# cancel slot timeout too
proc blinkstop {w} {
    global ob

    after cancel blinkloop $w

    if {$ob(laser)} {
	$w coords laser {0.0 0.0 0.0 0.0}
    }

    # why is this !dynamic here?
    if {!$ob(dynamic)} {
	after cancel do_slot_timeout
	cancel_mb_timeouts
    }
    set ob(blinking) no
}

# the real action happens in xyloop on ball cursor hits.

# blink target ball every half second, or ob(blinkrate)

proc blinkloop {w} {
    global ob

    if {$ob(in_clock_exit)} {return}

    # blink alternate colors
    if {$ob(blinki) % 2} {
	set color $ob(ball,col,1)
    } else {
	set color $ob(ball,col,2)
    }

    if {$ob(grasp_squeeze_game)} {
	$w itemconfig grasp_squeeze_target -outline $color
	color_ball black $ob(ball,next,dir)
    } else {
	# the normal case
	# the current target ball
	# color_ball $color $ob(ball,next,id)
	set blinkball $ob(ball,next,dir)
	# don't move the blinking ball for playback_static
	if $ob(static) {
	    set blinkball C
	}
	color_ball $color $blinkball
    }

    set blinkrate [expr {int(1000.0 * $ob(blinkrate))}]
    after $blinkrate blinkloop $w
    incr ob(blinki)
}

# start the cursor motion loop
proc xyinit {w} {
    # give the lkm time to unpause, or rshm will return 0's
    after 100 xyloop $w
}

# handle grasp stuff in xyloop

proc grasp_xyloop {w} {
    global ob

    if {!$ob(blinking)} {
	grasp_clear_drag_state
	return
    }

    if {$ob(grasp_games)} {
	set ob(screen,x) $ob(curcan,x)
	set ob(screen,y) $ob(curcan,y)

	grasp_iter $w
	set ob(hand_pos) [rshm hand_pos]
    
        set ob(hand_pos) [bracket $ob(hand_pos) 0.001 0.200]

	if {$ob(grasp_squeeze_game)} {
	    if {$ob(hand_pos) < $ob(hand_closed_target)} {
		set ob(hand_pos) $ob(hand_closed_target)
	    }
	    set gsize [rangemap $ob(hand_closed_target) $ob(hand_open_target) $ob(grasp_squeeze_small) $ob(grasp_squeeze_big) $ob(hand_pos)]
	    set gsize [expr {$gsize * $ob(scale)}]
	    $w coords grasp_squeeze_cursor [centxy 0 0 $gsize]
	}
    }
}

# generate press and release,
# for when we need to fake the events on timeouts

proc grasp_generate_press {} {
	global ob

# dtime "grasp_generate_press"
	set ob(grasp_state) closed
	event generate $ob(bigcan) <<GraspPress>>
}

proc grasp_generate_release {} {
	global ob

# dtime "grasp_generate_release"
	set ob(grasp_state) open
	event generate $ob(bigcan) <<GraspRelease>>
}

proc grasp_squeeze_game_metric {inout} {
    global ob mob
    set hand_slotlen [expr {abs($ob(hand_open_mvbox) - $ob(hand_closed_mvbox))}]
    set ap [rshm hand_active_power]
    if {$hand_slotlen < 0.001} {set hand_slotlen 1.0}
    set pct [expr {100. * $ap / $hand_slotlen}]
    if {$pct > 100.0} {set pct 100.0}
    wshm hand_npoints 0
    wshm hand_active_power 0
    wshm done_hand_pct_$inout $pct
    ctadd hand_ap_$inout $pct
}

proc grasp_squeeze_game_press {x y w} {
    global ob mob

    if {!$ob(blinking)} {
	return
    }

    hand_arrow $w 0 0 last
    indarrow_show $w

    if {$ob(grasp_just_closed)} {
	return
    }

# dtime "grasp_squeeze_game_press $ob(grasp_squeeze_count) f $ob(hand_pos)"

    grasp_squeeze_game_metric in

    incr ob(next_squeeze_target_number)
    wshm targetnumber $ob(next_squeeze_target_number)

    incr ob(grasp_squeeze_count)

    set ob(grasp_just_closed) yes
    after 200 {set ::ob(grasp_just_closed) no}

    $w coords grasp_squeeze_target [centxy 0 0 $ob(grasp_squeeze_big)]
    $w scale grasp_squeeze_target 0 0 $ob(scale) [expr {-$ob(scale)}]
    clock_beep 1

    hand_grasp_open

    if {$ob(slottimeout) > 0.0} {
	set timo [expr {int($ob(slottimeout) * 1000)}]
	after $timo grasp_generate_release
    }
}

proc grasp_squeeze_game_release {x y w} {
    global ob mob

# dtime "grasp_squeeze_game_release top"
    if {!$ob(blinking)} {
	return
    }

    hand_arrow $w 0 0 first
    indarrow_show $w

    if {$ob(grasp_just_opened)} {
	return
    }

### this is a nice place to divide debug output with a blank line.
### for hand squeeze game only
### puts ""
# dtime "grasp_squeeze_game_release $ob(grasp_squeeze_count) f $ob(hand_pos)"

    grasp_squeeze_game_metric out

    incr ob(next_squeeze_target_number)
    wshm targetnumber $ob(next_squeeze_target_number)

    incr ob(grasp_release_count)

    enter_target_ball grasp

    set ob(grasp_just_opened) yes
    after 200 {set ::ob(grasp_just_opened) no}

    $w coords grasp_squeeze_target [centxy 0 0 $ob(grasp_squeeze_small)]
    $w scale grasp_squeeze_target 0 0 $ob(scale) [expr {-$ob(scale)}]
    clock_beep 2

    # pause after 80 here, and display mini metric if needed
    set ob(score) "$mob(hits)/$ob(nslots)"
# dtime "grasp_squeeze_game_release mob(hits) $mob(hits))"
    if {$ob(grasp_squeeze_metric) && !($mob(hits) % 80)} {
	pause_target
	return
    }

    hand_grasp_close

    if {$ob(slottimeout) > 0.0} {
	set timo [expr {int($ob(slottimeout) * 1000)}]
	after $timo grasp_generate_press
    }
}

proc grasp_squeeze_pm_display {} {
    global ob mob

    set hits $mob(hits)

    if {!$ob(grasp_squeeze_metric)} return
    set in [expr {int([ctget hand_ap_in -avgn])}]
    set out [expr {int([ctget hand_ap_out -avgn])}]
    puts "Hand Metric: hits: $hits: in: $in %, out: $out %"

    # the quotes are for Tcl, not for the shell.
    exec zenity --info "--title=Hand Metric" \
"--text=<span font_desc=\"Sans 24\">Hand Metric
Hits $hits

Squeeze: $in %
Release: $out %</span>" >& /dev/null &

    ctreset hand_ap_in
    ctreset hand_ap_out
}

proc grasp_pick_game_press {x y w} {
    global ob

    if {!$ob(blinking)} {
	grasp_clear_drag_state
	return
    }

    hand_grasp_cancel

    incr ob(grasp_squeeze_count)

# dtime "grasp_pick_game_press $ob(grasp_squeeze_count) f $ob(hand_pos)"

    grasp_mark $x $y $w
    clock_beep 1

    set ob(grasp_just_closed) yes
    after 200 {set ::ob(grasp_just_closed) no}

    set dest $ob(ball,$ob(ball,next,dir),center)
# dtime "pick press $ob(ball,next,dir) $dest last"
    eval hand_arrow $w $dest last
    indarrow_hide $w

# patient must squeeze on their own to hold token
    hand_grasp_open_slot
}

proc grasp_pick_game_release {x y w} {
    global ob mob

    if {!$ob(blinking)} {
	grasp_clear_drag_state
	return
    }

    hand_grasp_cancel

    if {$ob(grasp_just_opened)} {
	return
    }
    incr ob(grasp_release_count)

    if {$ob(grasp_carrying_token) && $ob(cursor_near_target)} {
	incr ob(grasp_score)
    }
    set ob(grasp_score_str) "$ob(grasp_score)/$mob(hits)"

# dtime "grasp_pick_game_release $ob(grasp_release_count) f $ob(hand_pos)"

    clock_beep 2

    set ob(grasp_just_opened) yes
    after 200 {set ::ob(grasp_just_opened) no}
    set dest $ob(ball,$ob(ball,next,dir),center)
# dtime "pick release $ob(ball,next,dir) $dest last"
    eval hand_arrow $w $dest first
}

proc grasp_pick_game_motion {x y w} {
    global ob

    if {!$ob(blinking)} {
	grasp_clear_drag_state
	return
    }

    grasp_drag $x $y $w
    if {$ob(grasp_indicate) == "close"} {
	set inout first
    } else {
	set inout last
    }
#####    # move arrows with token
#####    hand_arrow $w $ob(grasp_token,x) $ob(grasp_token,y) $inout
#####    $w itemconfig indarrow -state normal
}

proc grasp_pick_show_token {w} {
# dtime "show token"
    $w itemconfig grasp_token -state normal
    indarrow_show $w
}

proc grasp_pick_hide_token {w} {
# dtime "hide token"
    $w itemconfig grasp_token -state hidden
    indarrow_hide $w
}

proc grasp_reach_game_press {x y w} {
    global ob

    if {$ob(grasp_just_closed)} {
	return
    }

    hand_grasp_cancel

    incr ob(grasp_squeeze_count)

# dtime "grasp_reach_game_press $ob(grasp_squeeze_count) f $ob(hand_pos)"

    set ob(grasp_just_closed) yes
    after 200 {set ::ob(grasp_just_closed) no}
    clock_beep 1
}

proc grasp_reach_game_release {x y w} {
    global ob

    if {$ob(grasp_just_opened)} {
	return
    }

    hand_grasp_cancel

    incr ob(grasp_release_count)

# dtime "grasp_reach_game_release $ob(grasp_release_count) f $ob(hand_pos)"

    clock_beep 2
    set ob(grasp_just_opened) yes
    after 200 {set ::ob(grasp_just_opened) no}
}

# clearing the drag array releases a grasped item
# if it is being held.
# this may happen if the patient actually releases,
# or if we want to force the software to release,
# like when the patient doesn't release when a target times out.
# (see the end of leave_target_ball)
# note that the drag state is only relevant in the pick game
# (the other games don't drag) but it doesn't hurt to call from other places.

proc grasp_clear_drag_state {} {
    global drag
    arrayunset drag
}

# hand_arrow - draw hand arrow
# w canvas widget
# posx posy center point between arrows
# inout - arrows point first (in) or last (out)
# color (gray80 by default)

proc hand_arrow {w posx posy inout {color gray80}} {
    global ob

# dtime "hand_arrow $posx $posy $inout $ob(ball,next,dir)"
# call_trace

    # delete previous
    $w delete indarrow

    set width 10
    set length .02
    set dist .03

    set s $dist
    set d [expr {$dist + $length}]
    $w create line [list $s 0 $d 0] -tags "indarrow east" -state hidden

    set s [expr {0 - $s}]
    set d [expr {0 - $d}]
    $w create line [list $s 0 $d 0] -tags "indarrow west" -state hidden

    $w move indarrow $posx $posy

    $w scale indarrow 0 0 $ob(scale) -$ob(scale)
    $w itemconfig indarrow -width $width
    $w itemconfig indarrow -arrow $inout
    $w itemconfig indarrow -arrowshape {20 20 10}
    $w itemconfig indarrow -fill $color
    indarrow_hide $w

    $w raise indarrow
}

proc indarrow_show {w} {
    $w itemconfig indarrow -state normal
}

proc indarrow_hide {w} {
    $w itemconfig indarrow -state hidden
}

proc grasp_open_indicate {} {
    global ob

# dtime "grasp_open_indicate"
    set ob(grasp_indicate) open
    set w $ob(bigcan)
    if {$ob(grasp_pick_game)} {
	$w itemconfig grasp_token  -width 10
    }
    if {$ob(grasp_reach_game)} {
        $w itemconfig grasp_reach_ring -dash {1 20}
    }
    $w itemconfig indarrow -arrow last
    indarrow_show $w
}

proc grasp_close_indicate {} {
    global ob

# dtime "grasp_close_indicate"
    set ob(grasp_indicate) close
    set w $ob(bigcan)
    if {$ob(grasp_pick_game)} {
	$w itemconfig grasp_token -dash {} -width 2
    }
    if {$ob(grasp_reach_game)} {
	$w itemconfig grasp_reach_ring -dash {}
    }
    $w itemconfig indarrow -arrow first
    indarrow_show $w
}

# movebox funcs for the hand

proc hand_grasp_cancel {} {

# dtime "hand_grasp_cancel"

    after_cancel_match hand_grasp_open
    after_cancel_match hand_grasp_close
    after_cancel_match grasp_generate
}

# open slot, then close hand after delay

proc hand_grasp_close {{ticks 400}} {
    global ob

# dtime "hand_grasp_close"
    hand_grasp_cancel

    grasp_close_indicate

    if {!$ob(planarhand_grasp_games)} { return }

    if {!$ob(motorforces)} { return }

    if {$ob(hand_collapse)} {
	# set op $ob(hand_open_target)
	set op $ob(hand_open_stop)
	set cl $ob(hand_closed_mvbox)
	set src [list $op 0. 0. 0.]
	set dest [list $cl 0. 0. 0.]
	set src [point_to_collapse $src $dest]

# squeeze game is a full timeout
# others are just timing out a hand move in a planarhand game
	if {$ob(grasp_squeeze_game)} {
	    set ams [expr {int($ob(slottimeout) * 1000)}]
	} else {
	    set ams [expr {int($ticks * 5 * 1.10)}]
	}

	set prewait [expr {int($ticks * 5 * 0.5)}]
	set mticks [expr {int($ticks * 0.5)}]
	after $ams hand_grasp_close_timeout
	hand_grasp_open_slot
# dtime "collapse after $prewait hand_grasp_close_move $mticks $src $dest"
	after $prewait hand_grasp_close_move $mticks [list $src] [list $dest]
    } else {
	set op $ob(hand_open_target)
	set cl $ob(hand_closed_mvbox)
	set src [list $op 0. 0. 0.]
	set dest [list $cl 0. 0. 0.]

# dtime "no collapse close_move now"
	hand_grasp_close_move $ticks $src $dest
    }
}

proc hand_grasp_close_move {ticks src dest} {
# dtime "hand_grasp_close_move $ticks  $src  $dest"
    movebox 1 22 [list 0 $ticks 1] $src $dest
}

proc hand_grasp_close_timeout {} {
# dtime "hand_grasp_close_timeout generate press"
    grasp_generate_press
}

# open slot, then open hand after delay

proc hand_grasp_open {{ticks 400}} {
    global ob

# good place to divide debug output
# dtime "hand_grasp_open"
    hand_grasp_cancel

    grasp_open_indicate

    if {!$ob(planarhand_grasp_games)} { return }

    if {!$ob(motorforces)} { return }

# people will probably overrun the targets,
# so make this open motion start at the closed stop instead of target
    if {$ob(hand_collapse)} {
	# set cl $ob(hand_closed_target)
	set cl $ob(hand_closed_stop)
	set op $ob(hand_open_mvbox)
	set src [list $cl 0. 0. 0.]
	set dest [list $op 0. 0. 0.]
	set src [point_to_collapse $src $dest]

# squeeze game is a full timeout
# others are just timing out a hand move in a planarhand game
	if {$ob(grasp_squeeze_game)} {
	    set ams [expr {int($ob(slottimeout) * 1000)}]
	} else {
	    set ams [expr {int($ticks * 5 * 1.10)}]
	}

	set prewait [expr {int($ticks * 5 * 0.5)}]
	set mticks [expr {int($ticks * 0.5)}]
	after $ams hand_grasp_open_timeout
	hand_grasp_open_slot
# dtime "collapse after $prewait hand_grasp_open_move $mticks $src $dest"
	after $prewait hand_grasp_open_move $mticks [list $src] [list $dest]
    } else {
	set cl $ob(hand_closed_target)
	set op $ob(hand_open_mvbox)
	set src [list $cl 0. 0. 0.]
	set dest [list $op 0. 0. 0.]

# dtime "no collapse open_move now"
	hand_grasp_open_move $ticks $src $dest
    }
}

proc hand_grasp_open_move {ticks src dest} {
# dtime "hand_grasp_open_move $ticks  $src  $dest"
    movebox 1 22 [list 0 $ticks 1] $src $dest
}

proc hand_grasp_open_timeout {} {
# dtime "hand_grasp_open_timeout generate release"
    grasp_generate_release
}

# open slot bounded at the hand mvbox targets
proc hand_grasp_open_slot {} {
    global ob

    if {!$ob(hand_collapse)} {
# dtime "hand_grasp_open_slot no collapse return"
        return
    }

    set cl $ob(hand_closed_mvbox)
    set op $ob(hand_open_mvbox)
    set src [list $cl 0. 0. 0.]
    set dest [list $op 0. 0. 0.]
    set src [point_to_collapse $src $dest]
# dtime "hand_grasp_open_slot $src"
    movebox 1 22 {0 1 0} $src $src
}

proc hand_grasp_release {} {
# dtime "hand_grasp_release"
    stop_movebox 1
}

proc hand_grasp_center {} {
    global ob

    if {!$ob(planarhand_grasp_games)} { return }

    # if {!$ob(motorforces)} { return }

# dtime "hand_grasp_center"

    set cl $ob(hand_closed_mvbox)
    set op $ob(hand_open_mvbox)

    set src [list $cl 0. 0. 0.]
    set dest [list $op 0. 0. 0.]
    # ignore ob(hand_collapse) here
    set src [point_to_collapse $src $dest]
    movebox 1 22 [list 0 200 1] $src $dest
}

# compass projection point (currently not used)
# calculate the projection on the straight line from 8 compass points
# the projection (for these diags only) is av(abs(x)+abs(y))
proc cproj {x y dir} {
    set dir [string toupper $dir]
    set av [expr {abs($x) + abs($y) / 2.}]
    set nav [expr {0.0 - $av}]
    switch $dir {
    N {return [list 0.0 $y]}
    NE {return [list $av $av]}
    E {return [list $x 0.0]}
    SE {return [list $av $nav]}
    S {return [list 0.0 $y]}
    SW {return [list $nav $nav]}
    W {return [list $x 0.0]}
    NW {return [list $nav $av]}
    default {return [list 0.0 $y]}
    }
}

# rotate a point about the origin in 2d space
proc rot2d {x y theta} {
    set rx [expr {cos($theta) * $x - sin($theta) * $y}]
    set ry [expr {sin($theta) * $x + cos($theta) * $y}]
    return [list $rx $ry]
}

# rotate point from/to compass dir wrt +X axis
proc crot2d {x y ft dir} {
    set dir [string toupper $dir]
    # get octant
    set oct 2
    switch $dir {
    SE {set oct 7}
    S {set oct 6}
    SW {set oct 5}
    W {set oct 4}
    NW {set oct 3}
    N {set oct 2}
    NE {set oct 1}
    E {set oct 0}
    default {set oct 2}
    }
    set sign 1.
    if {$ft == "from"} {set sign -1.}
    set theta [expr $sign * $oct * atan(1.)]
    return [rot2d $x $y $theta]
}

proc curscale {x y} {
    global ob

    set dir $ob(edge)
    foreach {rx ry} [crot2d $x $y from $dir] break
    set ry [expr {$ry * $ob(curscaleval)}]
    foreach {nx ny} [crot2d $rx $ry to $dir] break
    return [list $nx $ny]
}

proc do_shoulderarrow {w} {
    global ob

    # show green/yellow/red based on magnitude.
    # if it's close to zero, make it so it doesn't flicker
    # adjust length for 10cm or 14cm slots
    if {$ob(shoulderarrow)} {
	set ftz [rshm ft_zworld]
	set ftstatus [rshm ft_status]
	if {abs($ftz) < 1.0} {
	    set ftz -1.0
	}
	set ftz [bracket $ftz -75.0 75.0]
	set dispftz [expr {$ftz / ($ob(scale) / 4.) * $ob(slotlength) / 0.14}]
	set fx $ob(forcearrowx)
	set ftcolor green1

	if {abs($ftz) > 40.0} {
	    set ftcolor yellow
        }

	if {abs($ftz) > 60.0} {
	    set ftcolor red
	}

	if {abs($ftstatus) != 0 || abs($ftz) > 70.0} {
	    place .fdisp -in .
	    set dispftz 0.0
        } else {
	    place forget .fdisp
	}

	$w itemconfig forcearrow -fill $ftcolor
	$w coords forcearrow [list $fx 0.0 $fx $dispftz]
	$w scale forcearrow 0 0 $ob(scale) -$ob(scale)
    }
}

# the cursor motion loop, runs 20x/sec
proc xyloop {w} {
    global ob mob

    if {$ob(in_clock_exit)} {return}

    # 20x / sec
    after 50 xyloop $w

    # get world space coords,
    # for planar, meters, for wrist, radians
    set x [getptr x]
    set y [getptr y]

# the linear robot returns the position for both x and y.
# for now, in this part of the loop, use x, so the cursor goes up
# and down on the screen.  After we move the yellow ball, set
# x to y and y to 0, so that we can use x to move the robot.

    if {$ob(wrist)} {
	 foreach {x y} [wrist_ptr_scale $x $y] break
	 if {$ob(wrist_ps)} {
	     set y 0.0
	     set x [expr {[rshm wrist_ps_pos] / ($ob(wrist_ps_scale) / 2.)}]
	 }
    } elseif {$ob(linear)} {
	set x 0.0
# y now contains pos, x is 0
    }

if {$ob(docurscale)} {
     foreach {x y} [curscale $x $y] break
}

    set ob(cur,x) $x
    set ob(cur,y) $y

    # move the yellow cursor ball, scale, and flip its y
    $w coords cursor [centxy $x $y $ob(cur_ball_size)]
    set ob(curcan,x) [expr {$x * $ob(scale) + $ob(half,x)}]
    set ob(curcan,y) [expr {-$y * $ob(scale) + $ob(half,y)}]

    $w scale cursor 0 0 $ob(scale) [expr {-$ob(scale)}]
    # status_mes "[f3 x $x y $y cx $ob(curcan,x) y $ob(curcan,y)]"

    if {$ob(dopath)} {
	path_tick $x $y
    }

    grasp_xyloop $w

    do_shoulderarrow $w

    # no check for ball hit if target not blinking.
    # or static or no edge balls.

    if {!$ob(blinking) || $ob(static) || !$ob(nballs) || $ob(noballhit)} {
        return
    }

    # if adaptive, check the velocity magnitude.
    # if the patient's hand has moved enough, start the slot now.
    adap_check_velmag

    # dist is distance between cursor and target.
    # gdist is distance between token and target.
    # (the cursor may be moving without the token)

    # did the cursor enter the next target ball?
    # see if the cursor is close enough to ball,next
    set curx $x
    set cury $y
    set dir $ob(ball,next,dir)
    set nextx [lindex $ob(ball,$dir,center) 0]
    set nexty [lindex $ob(ball,$dir,center) 1]
    set dist [edist $curx $cury $nextx $nexty]

    set ob(cursor_near_target) [expr {$dist < $ob(hitradius)}]

    # in non-grasp games, don't skip hit check
    set skip_hit_check no

    # in grasp games, do proximity check when hit conditions are not met.

    # in pick, check
    # if not carrying always
    # if carrying, when released
    if {$ob(grasp_pick_game)} {
        # carrying the token?
        set gtx $ob(grasp_token,x)
        set gty $ob(grasp_token,y)
        # distance from cursor to token
        set ctdist [edist $curx $cury $gtx $gty]
	set ob(grasp_carrying_token) [expr {$ctdist < $ob(hitradius)}]

	# status_mes "xyloop pick carrying $ob(grasp_carrying_token) just_opened released $ob(grasp_just_opened)"

	# skip hit check?
	set skip_hit_check yes
	if {!$ob(grasp_carrying_token)} {
	    set skip_hit_check no
	}
	if {$ob(grasp_carrying_token) && $ob(grasp_just_opened)} {
	    set skip_hit_check no
	}

	# open on first approach
	if {$ob(cursor_near_target)} {
	    if {$ob(grasp_pick_first_approach)} {
		hand_grasp_open
		set ob(grasp_pick_first_approach) no
	    }
	}
    }

    # in reach
    # check when released
    if {$ob(grasp_reach_game)} {
	if {$ob(grasp_just_closed)} {
	    set ob(grasp_just_closed) no
	    hand_grasp_open
	}
	set skip_hit_check yes
	if {$ob(grasp_just_opened)} {
	    set skip_hit_check no
	}

	# if we are near the target, show the grasp_reach_ring
	if {$ob(cursor_near_target)} {
	    $w itemconfig grasp_reach_ring -state normal
	    indarrow_show $w
	    if {$ob(grasp_reach_first_approach)} {
		hand_grasp_close
		set ob(grasp_reach_first_approach) no
	    }
	} else {
	    $w itemconfig grasp_reach_ring -state hidden
	    indarrow_hide $w
	}
    }

    # without this throttle, logging can choke opening the crob_out pipe
    # if the last hit was within the last 200ms, skip the hit check
    set now [clock clicks -mill]
    set dhit [expr {$now - $ob(last_start_log_time)}]
    if {$ob(log) && $dhit < 200} {
	set skip_hit_check yes
    }

    # did the cursor hit the target ball?
    if {!$skip_hit_check && $ob(cursor_near_target)} {
	# puts "$curx $cury $nextx $nexty  edist: $dist"
	enter_target_ball hit
	if {$ob(blinking)} {
	    set ballid $ob(ball,$dir,id)
	    leave_target_ball $ballid $ob(bigcan) hit
	}
    }

    # display laser when it's active and ticking.
    # clear laser when it's active and not ticking.
    if {$ob(laser)} {
	if {$ob(blinking)} {
	    do_laser $w $curx $cury $nextx $nexty
	} else {
	    $w coords laser {0.0 0.0 0.0 0.0}
	}
    }

    wm title . "$ob(gamename) $ob(patname)    Average Time: $mob(avgtime)    Hits: $mob(hits)"

# see linear x/y comment above
    if {$ob(linear)} {
	set x $y
	set y 0.0
# x now contains pos, y is 0
    }

    set ob(cur,x) $x
    set ob(cur,y) $y
}

# line to point distance
# lpdist handlex handley ballx bally velx vely
#

proc lpdist {x y xc yc vx vy} {

    set eps .001
    set pi2 [expr {2.*atan(1.0)}]
    set atn [expr {atan2($vy,$vx)}]
    set mag [expr {hypot($vy,$vx)}]

    # if the magnitude is low, return a bignum.
    if {$mag < $eps } {
	    set ret 100.0
	    # puts "lpdist speed $mag"
	    return $ret
    }

    # puts "atan $atn"
    # check for orthogonal
    if {(((abs($atn - (0. * $pi2))) < $eps) ||
	 ((abs($atn - (2. * $pi2))) < $eps))} {
	    set ret [expr {abs($y - $yc)}]
	    # puts "lpdist ret 90- $ret"
	    return $ret
    }

    if {(((abs($atn - (1. * $pi2))) < $eps) ||
	 ((abs($atn - (3. * $pi2))) < $eps))} {
	    set ret [expr {abs($x - $xc)}]
	    # puts "lpdist ret 180| $ret"
	    return $ret
    }

    if {$vx < $eps} {
	    set ret [expr {abs($y - $yc)}]
	    # puts "lpdist vx $vx $ret"
	    return $ret
    }

    # why is ob(cur) set here??
    set ob(cur,x) $x
    set ob(cur,y) $y

    set a [expr { $vy / $vx }]
    set b [expr { $y - $vy / $vx * $x }]
    set bc [expr { $yc + 1/$a * $xc }]
    set xi [expr { ($bc - $b) / ($a + 1/$a) }]
    set yi [expr { $a * $xi + $b }]
    set ret [expr { hypot ($xi-$xc, $yi-$yc) }]

    return $ret
}

# x1 y1 cursor
# x2 y2 next ball
# xmag is a multiplier to turn the velocity vector
# into a constant length drawn vector with the same direction as the velocity
# imag is the width of the drawn vector, based on speed
proc do_laser {w x1 y1 x2 y2} {
	global ob

	set vx 0.0
	set vy 0.0
	if $ob(planar) {
		set vx [rshm xvel]
		set vy [rshm yvel]
	}
	if $ob(wrist) {
		set vx [rshm wrist_fe_vel]
		set vy [rshm wrist_aa_vel]
	}
	set mag [expr {hypot($vx,$vy)}]
	set imag [expr {int(100. * $mag)}]
	set xmag 1.0
	if {$mag > 0.01} {
	    set xmag [expr {$ob(slotlength) / $mag}]
	}
	if $ob(wrist) {
	    set imag [expr {$imag / 8}]
	}
	set ahx [expr {$x1 + $vx * $xmag}]
	set ahy [expr {$y1 + $vy * $xmag}]
	if {$imag > 20} {set imag 20}
	set dist [lpdist $x1 $y1 $x2 $y2 $vx $vy]
	# status_mes "dist [format %.3f $dist]"

	# if laser is good/scoring, green, else red
	if {$dist < $ob(laser_dist)} {
	    $w itemconfig laser -fill green1
	    incr ob(laser_score) $imag
	} else {
	    $w itemconfig laser -fill red
	}

	$w coords laser [list $x1 $y1 $ahx $ahy]
	$w scale laser 0 0 $ob(scale) -$ob(scale)
	$w itemconfig laser -width $imag
}

# this handles the menu clock and the red/green center of the clock
# only called when you hit a target ball.

proc bumpclock {} {
    global ob mob

    # rolling average
    set avi $ob(avi)

    set t1 [clockms]
    set dt [expr {$t1 - $ob(t0)}]
    set ob(avgtime) [expr {$ob(avgtime) + $dt - $ob(avg,$avi)}]

    # change blue/red/green if we want.
    if {$mob(thresh) > 0 && $ob(avgtime) > $mob(thresh) * 10} {
	set acol firebrick
    } else {
	set acol darkgreen
    }
    set mob(avgtime) [format %.3f [expr {($ob(avgtime)/($ob(avn)*1000.0))}]]
    $ob(bigcan) itemconfigure inner -fill $acol

    set ob(avg,$avi) $dt
    set ob(avi) [expr {($avi + 1) % $ob(avn)}]

    set mob(hittime) [expr {$dt/1000.0}]
    set ob(t0) $t1
}

# some simple games have no edge balls
# (circle and shoulder)
# these get called by enter/leave_target_ball

proc enter_target_noedgeballs {} {
    global ob mob

    enter_target_stop_log

    # done with this session??
    if {$mob(hits) >= $ob(nslots)} {
	clock_exit
    }
}

proc leave_target_noedgeballs {} {
    global ob
    set ob(edge) ""
    set ob(edgedir) ""
    set ob(slotpairnum) $ob(slotnum)
# dtime "lt_noedge zeroed edge/dir"

    leave_target_start_log
}

proc do_boom {dir} {
    global ob

    $ob(bigcan) itemconfig $ob(boom,$dir,id) -state normal
    after 200 $ob(bigcan) itemconfig $ob(boom,$dir,id) -state hidden
}

# this happens when the cursor enters a target ball
# the end of a slot.

# a slot is delimited by events associated with the cursor hitting a ball:
# 1) enter_target_ball
# this is the stuff that happens at the end of a slot,
# when you enter the target ball.
# 2) leave_target_ball
# this is the stuff that happens at the beginning of a slot,
# when you leave the target ball.
# these usually happen one right
# after the other, but if you confuse them, life gets messy.

# cause can either be hit, slot_timeout, grasp, or pause

proc enter_target_ball {cause} {
    global ob mob

    set w $ob(bigcan)

# dtime "etb $cause"

    # start by clearing the status message
    # status_mes ""
# status_mes "etb $cause"

    enter_target_stop_log

    incr mob(hits)
    incr ob(slotnum)
    # this is the big yellow screen display
    # it shows how many hits have already happened, starting with N.
    set ob(score) "$mob(hits)/$ob(nslots)"
    if {$ob(grasp_reach_game)} {
	$w itemconfig grasp_reach_ring -state hidden
	indarrow_hide $w
	set ob(grasp_reach_first_approach) yes
    }

    if {$ob(grasp_pick_game)} {
	set ob(grasp_pick_first_approach) yes
	set ob(grasp_score_str) "$ob(grasp_score)/$mob(hits)"

	# if pick not carrying token, make sure hand opens
	if {$ob(grasp_pick_game)} {
	    if {!$ob(grasp_carrying_token) && $ob(grasp_state) == "closed"} {
# dtime "hgo"
		hand_grasp_open
	    }
	}
    }

    if {$ob(grasp_squeeze_game)} {
	if {$ob(grasp_squeeze_metric) && !($mob(hits) % 80)} {
	    set ob(just_ran_pm_display) yes
	    grasp_squeeze_pm_display
	}
    }

# dtime "etb cause $cause new hits $mob(hits) slotnum $ob(slotnum)"

    # if {$ob(enter_beep)} {
	    # catch {exec beep &} result
    # }

    if {$ob(enter_boom)} {
	do_boom $ob(ball,next,dir)
    }

    # in leave_target_ball, we set a timer in case the patient
    # doesn't hit the target on time.
    # if there's an old one, cancel it.
    after cancel do_slot_timeout
    cancel_mb_timeouts

    # no forces, like if the white ball was centering.
    if {!$ob(motorforces)} {
	if {!$ob(wrist)} {
	stop_movebox 0
	}
    }

    # no edge balls?  (shoulder and circle) handle in a different proc
    if {$ob(nballs) == 0} {
	enter_target_noedgeballs
	return
    }

    enter_target_do_adaptive $cause

    # done with this session??
    # first (center) ball is #1 when counting balls
    # exit 1 second after last target ball hit
    if {$mob(hits) >= $ob(nslots)} {
	clock_exit
    }
}

# if adaptive, check the velocity magnitude.
# if the patient's hand has moved enough, start the slot now.

proc adap_check_velmag {} {
    global ob

    if {$ob(adaptive)} {
	# if there is a movebox event pending...
	if {[info exists ob(mb2_after_id)]} {
	    if {$ob(slottime) <= 0.0} { set slot_time 1.0 }
	    # .40 (first term) controls the sensitivity of the velocity limit.
	    # .20 was too sensitive.  lower is more sensitive.
	    set ob(vellim) [expr {.40 * 1.875 * $ob(slotlength) / $ob(slottime)}]
	    set ob(velmag) [rshm velmag]

	    if {$ob(wrist)} {
	        if {$ob(wrist_ps)} {
		    set ob(velmag) [expr {abs([rshm wrist_ps_vel])}]
		    set ob(vellim) [expr {.80 * 1.875 * $ob(slotlength) / $ob(slottime)}]
		} else {
		    set ob(velmag) [rshm wrist_velmag]
		    set ob(vellim) [expr {.80 * 1.875 * $ob(slotlength) / $ob(slottime)}]
		}
	    }

	    # with linear, velmag is abs(vel).
	    if {$ob(linear)} {
		set ob(vellim) [expr {.20 * 1.875 * $ob(slotlength) / $ob(slottime)}]
		set ob(velmag) [expr {abs([rshm linear_vel])}]
	    }

	    set ob(adap_patient_moved) "no"

	    if {$ob(grasp_pick_game)} {
		if {$ob(grasp_state) == "open"} return

		set ob(adap_patient_moved) "yes"
		# the patient squeezed the handle
		ctadd initiate
# dtime "pick squeezed, cancel timeout and start movebox"
		# execute the command immediately.
		# mb_command will cancel the after.
		set mb_command [lindex [after info $ob(mb2_after_id)] 0]
clock_beep 1
		eval $mb_command
		return
	    }

	    if {$ob(velmag) > $ob(vellim)} {
		set ob(adap_patient_moved) "yes"
		# the patient moved the handle
		ctadd initiate

		# planarwrist movebox is handled in space.tcl
		if {$ob(planarwrist)}  return

# dtime "velmag $ob(velmag) > vellim $ob(vellim) cancel timeout and start movebox"
		# execute the command immediately.
		# mb_command will cancel the after.
		set mb_command [lindex [after info $ob(mb2_after_id)] 0]
clock_beep 1
		eval $mb_command
	    }
	}
    }
}

# set up change target, called by leave_target_ball

proc ltb_change_target {edge} {
    global ob

    # puts "ltb_change_target $edge"
    set ob(randedge) $edge
    set ndirs [llength $ob(dirs)]
    while {"$ob(randedge)" == "$edge"} {
	set randi [expr {int(rand() * $ndirs)}]
	set ob(randedge) [lindex $ob(dirs) $randi]
	# dtime "edge $edge randedge $ob(randedge)"
    }
    set change_time_ms [expr {int($ob(change_time) * 1000)}]
    after $change_time_ms change_target_cb $ob(randedge)
}

# callback, to change target in midslot

proc change_target_cb {randedge} {
    global ob

    # dtime "change_target_cb $randedge"
    set w $ob(bigcan)
    color_ball off ball

    # the colors are reversed between here and blinkloop,
    # because blinki has been post-incremented in blinkloop.
    if {$ob(blinki) % 2} {
	set color $ob(ball,col,2)
    } else {
	set color $ob(ball,col,1)
    }
    # set color green1
    set randtag $ob(ball,randedge,dir)
    # color_ball $color $randedge
    color_ball $color $randtag
    set ob(ball,next,id) $randedge
}

# this happens when the cursor ball exits a target ball
# the beginning of a slot.

proc leave_target_ball {ball w cause} {
    global ob mob

    if {$ob(in_clock_exit)} {return}

### this is a nice place to divide debug output with a blank line.
### puts ""
# dtime "ltb $cause"

    cancel_mb_timeouts

    # lazy - this fills all the balls
    if {!$ob(static)} {
	color_ball off ball
    }

    bumpclock

    # no forces, like if the white ball was centering.
    if {!$ob(motorforces)} {
	if {$ob(wrist)} {
	    if {$ob(wrist_ps)} {
		# center diff
		wshm wrist_ps_damp 0.0
		movebox 0 12 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	    } else {
		# center ps
		wshm wrist_diff_damp 0.0
		movebox 0 7 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	    }
	}
    }

    if {$ob(nballs) == 0} {
	leave_target_noedgeballs
	return
    }

    adap_stiff_adjust leave

    # box the binnacle!
    # figure out the next ball by ob(dirlist).
    set ob(new,this) $mob(hits)
    set ob(new,next) [expr {($mob(hits) + 1)}]

    set ob(ball,this,dir) [lindex $ob(dirlist) $ob(new,this)]
    set ob(ball,next,dir) [lindex $ob(dirlist) $ob(new,next)]
    set ob(ball,this,id) $ob(ball,$ob(ball,this,dir),id)
    set ob(ball,next,id) $ob(ball,$ob(ball,next,dir),id)
# dtime "ltb old $ball $ob(new,this) $ob(ball,this,dir) next $ob(new,next) $ob(ball,next,dir)"

    # find the positions of the ends of the slot
    set src $ob(ball,$ob(ball,this,dir),center)
    set dest $ob(ball,$ob(ball,next,dir),center)

    if {$ob(dynamic)} {
	# stay in the center!
	set src $ob(ball,C,center)
	set dest $ob(ball,C,center)
    }

    set ob(mbsrc) $src
    set ob(mbdest) $dest

    # convert slot time to number of samples for movebox
    set ob(slotticks) [expr {int($ob(slottime) * $ob(Hz))}]
    set ob(slotms) [expr {int($ob(slottime) * 1000)}]

    # these edge vars are for logfile naming
    set edgei $ob(new,this)
    incr edgei
    set ob(edge) [lindex $ob(dirlist) $edgei]
    # t for toward the edge
    set ob(edgedir) t
    # reset randedge for every target
    set ob(randedge) no

    if {$ob(ball,next,dir) == "C"} {
	set ob(edgedir) b
	incr edgei -1
	set ob(edge) [lindex $ob(dirlist) $edgei]
    } elseif {$ob(proto_change_target)} {
	# change target on "to" balls only
	# 2 because we only check on half the targets
	set rand [expr {rand()}]
        # puts "rand $rand"
	if {$rand < ($ob(change_pct) / 100.)} {
	    ltb_change_target $ob(edge)
	}
    }

# dtime "ltb $ob(edge)$ob(edgedir)$ob(slotnum) cause $cause"

    leave_target_start_log

    if {$ob(motorforces)} {
	# apply pre_wait if present
	# only apply pre_wait for linear at center
	set kpre_wait $ob(kpre_wait)
# dtime "ltb sched pre_wait $kpre_wait clock_movebox $ob(slotticks) $ob(mbsrc) $ob(mbdest)"
	set ob(pre_wait_after_id) [after $kpre_wait [list clock_movebox {0 $ob(slotticks) 1} $ob(mbsrc) $ob(mbdest)]]
	set ob(mb_state) pre_wait
    }

    # schedule slot timeout event if we're using it.
    if {$ob(slottimeout) > 0.0} {
	set timo [expr {int($ob(slottimeout) * 1000)}]
	if {$ob(linear) || $ob(wrist_ps)} {
	    # set timo [expr {$ob(kpre_wait) + $ob(slotms) }]
	    set timo [expr {$ob(kpre_wait) + $timo }]
	}

# dtime "ltb sched do_slot_timeout $ob(slottimeout) timo $timo"
	after cancel do_slot_timeout
	after $timo do_slot_timeout
    }

    # since we hit a target ball, do this immediately.
    # (do not wait for the blink routine)
    # flip color

    if {$ob(blinki) % 2} {
	set color $ob(ball,col,1)
    } else {
	set color $ob(ball,col,2)
    }

    # color_ball $color $ob(ball,next,id)
    # don't color outside targets when static
    if {!$ob(static)} {
        color_ball $color $ob(ball,next,dir)
    }

    if {$ob(start_led)} {
        start_led_on
        after 100 start_led_off
    }

    # grasp squeeze game has no targets

    # move the green reach ring to the new dest
    if {$ob(grasp_reach_game)} {
	set x [lindex $dest 0]
	set y [lindex $dest 1]
	$w coords grasp_reach_ring [centxy $x $y $ob(grasp_reach_ring_size)]
	$w scale grasp_reach_ring 0 0 $ob(scale) -$ob(scale)
	hand_arrow $w $x $y first
    }

    # move the token to the new source, in case the patient didn't
    if {$ob(grasp_pick_game)} {
	# center the grasp_token at the current cursor
	set x [lindex $src 0]
	set y [lindex $src 1]
	$w coords grasp_token [centxy $x $y $ob(grasp_token_size)]
	$w scale grasp_token 0 0 $ob(scale) -$ob(scale)

	# make the grasp token disappear for .5 seconds
	grasp_pick_hide_token $::ob(bigcan)
	# timing kludge
	after 10 indarrow_hide $w
	grasp_clear_drag_state
	# pick close ltb +1sec
	# hand_grasp_cancel

	hand_arrow $w $x $y last

	after 500 grasp_pick_show_token $::ob(bigcan)
	if {$ob(grasp_state) == "open"} {
# dtime "ltb hand grasp_close after 500 ms"
	    after 500 hand_grasp_close
	    after 500 hand_arrow $w $x $y first
	    after 500 indarrow_show $w
	} else {
	    # give them a change to grab the next one
	    hand_grasp_open
	}
    }
}

proc start_led_on {} {
# dtime "led on"
    wshm dout0 1
}

proc start_led_off {} {
# dtime "led off"
    wshm dout0 0
}


# logging

# the log file name format (without spaces)
# andy_tannenbaum / eval / 20011105_Mon / point_to_point_165736 _ pNb1.dat

# open logfile-per-run and logfile-per-slot.

proc leave_target_start_log {} {
    global ob mob
    if {$ob(log)} {
        if {$ob(nballs) == 0} {
	    set ob(slotpairnum) [expr {$mob(hits) + 1}]
	} else {
	    set ob(slotpairnum) [expr {($mob(hits) / 2) + 1}]
	}
	set ob(tailname) [file tail $ob(gamename)]

	if {$ob(logperslot)} {
	    if {"$ob(randedge)" != "no"} {
		# if we were going W and then changed to S, it will be:
	        # filename will be wr_changexS_nnnnnn_Wtnn.dat
		set slotlogfilename [join [list $ob(tailname)x$ob(randedge) $ob(timestamp)\
		  $ob(edge)$ob(edgedir)$ob(slotpairnum).dat] _]
		set slotlogfilename [file join $ob(dirname) $slotlogfilename]

	        # no status_mes real filename, it would be a clue.
		set fakeslotlogfilename [join [list $ob(tailname) $ob(timestamp)\
		  $ob(edge)$ob(edgedir)$ob(slotpairnum).dat] _]
		start_log $slotlogfilename $ob(logvars) $ob(pathlenfilename)
		set fakeslotlogfilename [file join $ob(dirname) $fakeslotlogfilename]
		status_mes "per slot $fakeslotlogfilename"
	    } else {
		set slotlogfilename [join [list $ob(tailname) $ob(timestamp)\
		  $ob(edge)$ob(edgedir)$ob(slotpairnum).dat] _]
		set slotlogfilename [file join $ob(dirname) $slotlogfilename]
		start_log $slotlogfilename $ob(logvars) $ob(pathlenfilename)
		status_mes "per slot $slotlogfilename"
	    }
	} elseif {$mob(hits) == 0} {
	    # start multi log on only first ball
	    set slotlogfilename [join [list $ob(tailname) $ob(timestamp)\
	      multi.dat] _]
	    set slotlogfilename [file join $ob(dirname) $slotlogfilename]
	    start_log $slotlogfilename $ob(logvars) $ob(pathlenfilename)
	    status_mes "per run $slotlogfilename"
	}

       # limit size of log files to ob(logtimemax)
       after cancel stop_log
       after $ob(logtimemax) stop_log
    }
}

# close logfile-per-slot.

proc enter_target_stop_log {} {
    global ob
    if {$ob(logperslot)} {
	stop_log
    }
    # never stop multi log on enter.
}

# for adaptive...
# see: qnx games/adapbrk_base.cpp and adapctr2.cpp

# 1x per slot, 16x per circuit

proc adap_slot_metrics {} {
    global ob mob slot_done

    if {![info exists slot_done]} {
	puts "$mob(hits): fast target, slot_done not set"
	puts $ob(adap_log_fd) "$mob(hits): fast target, slot_done not set"
	return
    }
    if {$slot_done(npoints) == 0} {
	puts "$mob(hits): npoints == $slot_done(npoints)"
	puts $ob(adap_log_fd) "$mob(hits): npoints == $slot_done(npoints)"
	return
    }
    if {$slot_done(mindist) > 1.0} {
	puts "$mob(hits): mindist == $slot_done(mindist)"
	puts $ob(adap_log_fd) "$mob(hits): mindist == $slot_done(mindist)"
	return
    }

    set npoints $slot_done(npoints)

    ctadd npoints48 $npoints
    ctadd npoints80

    # speed metric
    # read from slot_done
    set active_power $slot_done(active_power)
    set robot_power $slot_done(robot_power)
    set min_jerk_deviation $slot_done(min_jerk_deviation)
    set min_jerk_dgraph $slot_done(min_jerk_dgraph)
    set jerkmag $slot_done(jerkmag)
    set max_vel $slot_done(max_vel)

    # current avs
    # active power is not currently in use
    set av_active_power [expr {$active_power / $npoints}]
    set av_robot_power [expr {$robot_power / $npoints}]
    set av_min_jerk_deviation [expr {$min_jerk_deviation / $npoints}]
    set av_min_jerk_dgraph [expr {$min_jerk_dgraph / $npoints}]
    set av_jerkmag [expr {$jerkmag / $npoints}]
    # jerk div is not currently in use
    if {$max_vel > .0001} {
	    set av_jerkdiv [expr {$av_jerkmag / $max_vel}]
    } else {
	    # not moving.
	    set av_jerkdiv 0.0
    }
# puts "slot: av min jerk dev $av_min_jerk_deviation"
# dtime "av_mjdev $av_min_jerk_deviation av_mjgraph $av_min_jerk_dgraph"

    ctadd active_power16 $av_active_power
    ctadd active_power80 $av_active_power
    ctadd robot_power16 $av_robot_power
    ctadd robot_power80 $av_robot_power
    ctadd min_jerk_deviation16 $av_min_jerk_deviation
    ctadd min_jerk_deviation80 $av_min_jerk_deviation
    ctadd min_jerk_dgraph16 $av_min_jerk_dgraph
    ctadd min_jerk_dgraph80 $av_min_jerk_dgraph
    ctadd jerkmag80 $av_jerkmag
    ctadd jerkdiv80 $av_jerkdiv

    ctadd max_dist_along_axis16 $slot_done(maxdist)
    ctadd max_dist_along_axis80 $slot_done(maxdist)
    ctadd min_dist_from_target16 $slot_done(mindist)
    ctadd min_dist_from_target80 $slot_done(mindist)

    # the 1.5, 0.65, and 6.0 are derived in paper:
    # Krebs et al, 2003, Autonomous Robots journal.
    set min_jerk_metric 0.0
    if {$av_min_jerk_deviation > 0.0} {
	set min_jerk_metric [expr {6.0 * $av_min_jerk_deviation}]
    }
    set min_jerk_dgmetric 0.0
    if {$av_min_jerk_dgraph > 0.0} {
	set min_jerk_dgmetric [expr {6.0 * $av_min_jerk_dgraph}]
    }

    set active_power_metric 0.0
    if {$av_active_power < 0.0} {
	set active_power_metric [expr {0.65 * $av_active_power}]
    }
    set local_speed_metric [expr {$active_power_metric + $min_jerk_metric}]

    ctadd active_power_metric16 $active_power_metric
    ctadd min_jerk_metric16 $min_jerk_metric
    ctadd min_jerk_dgmetric16 $min_jerk_dgmetric
    ctadd speed_metric16 $local_speed_metric
    ctadd speed_metric48 $local_speed_metric

    # puts "av_active_power [ctget active_power16 -avgn] av_min_jerk_deviation [ctget min_jerk_deviation16 -avgn] sum_speed_metric [ctget speed_metric16]"

    # stiffness metric
    # read from ctlr
    set dist_straight_line_sq $slot_done(dist_straight_line_sq)
    set av_dist_straight_line_sq [expr {$dist_straight_line_sq / $npoints}]

    ctadd dist_straight_line_sq16 $av_dist_straight_line_sq
    ctadd dist_straight_line_sq80 $av_dist_straight_line_sq

    # puts "av_dist_straight_line_sq [ctget dist_straight_line_sq16 -avgn] sum_av_dist_straight_line_sq [ctget dist_straight_line_sq16]"

# dtime "slot: npoints $npoints active_power $active_power min_jerk_deviation $min_jerk_deviation min_jerk_dgraph $min_jerk_dgraph"

# dtime "slot: np $npoints mindft $slot_done(mindist) rp $av_robot_power jerk $av_jerkmag dfslsq $av_dist_straight_line_sq"

    # zero accumulated stuff in ctlr
    adap_zero_pm
}

# 1x per circuit, per 16 slots
# planar constants from qnx adapbrk_base.cpp

proc adap_circuit_metrics {} {
    global ob mob
    set nslots 16

    # speed
    # 16 slot avs

    set speed_performance_level -1
    set av_speed_metric [ctget speed_metric16 -avgn]
    if {$av_speed_metric > -0.01 && $av_speed_metric < 0.01} {
	set speed_performance_level 0
    }
    if {$av_speed_metric > 0.01} {
	set speed_performance_level 1
    }

    ctadd speed_performance_level3 $speed_performance_level

    # puts "1circ sum speed metric [ctget speed_metric16]"

    # stiffness
    set av_dist_straight_line_sq [ctget dist_straight_line_sq16 -avgn]

    # planar
    set xformsm 2.65
    set xformp -8.0
    set xformn -20.0
    if {$ob(wrist)} {
	set xformsm 0.18
	set xformp -8.0
	set xformn -2500.0
    }

    if {$av_dist_straight_line_sq == 0.0} {
	set stiff_metric 0.0
    } else {
	set stiff_metric [expr {$xformsm * sqrt($av_dist_straight_line_sq) \
	    - .00008 * $ob(adap_side_stiff)}]
    }

    if {$stiff_metric > 0.0} {
	set stiff_metric [expr {$xformp * $stiff_metric}]
    } else {
	set stiff_metric [expr {$xformn * $stiff_metric}]
    }

    set stiff_performance_level 0
    if {$stiff_metric > 0.01} {
	set stiff_performance_level 1
    }
    if {$stiff_metric < -0.01} {
	set stiff_performance_level -1
    }

    ctadd stiff_performance_level3 $stiff_performance_level

    ctadd stiff_metric16 $stiff_metric
    ctadd stiff_metric48 $stiff_metric

# puts "1circ sum stiff metric [ctget stiff_metric48]"

}

# 1x per 3 circuits, more often initially
proc adjust_adap_controller {} {
    global ob mob

    # speed
    set speed_alpha 0.25
# sum must be rounded.
    switch -- [ctget speed_performance_level3] {
    -3	{ set speed_alpha 1.0 }
    -2	{ set speed_alpha 0.5 }
    -1	{ set speed_alpha 0.25 }
    0	{ set speed_alpha 0.25 }
    1	{ set speed_alpha 0.5 }
    2	{ set speed_alpha 1.0 }
    3	{ set speed_alpha 2.0 }
    default { set speed_alpha 0.25 }
    }

    set speed_metric48 [ctget speed_metric48 -avgn]
    set ob(slottime) [expr {$ob(slottime) - $speed_alpha \
	* $ob(adap_time_range) * $speed_metric48}]

    # bracket
    if {$ob(slottime) < $ob(adap_min_time)} {
	set ob(slottime) $ob(adap_min_time)
    }
    if {$ob(slottime) > $ob(adap_max_time)} {
	set ob(slottime) $ob(adap_max_time)
    }

    # puts "\nslotnum $ob(slotnum)"
    # puts "adjust_adap: speed_alpha $speed_alpha slottime $ob(slottime) avg time per slot [expr {[ctget npoints48 -avgn] / (200.)}]"

    # stiff
    set stiff_alpha 0.25
    switch -- [ctget stiff_performance_level3] {
    -3	{ set stiff_alpha 1.0 }
    -2	{ set stiff_alpha 0.5 }
    -1	{ set stiff_alpha 0.25 }
    0	{ set stiff_alpha 0.25 }
    1	{ set stiff_alpha 0.5 }
    2	{ set stiff_alpha 1.0 }
    3	{ set stiff_alpha 2.0 }
    default { set stiff_alpha 0.25 }
    }

    set stiff_metric48 [ctget stiff_metric48 -avgn]
    set ob(adap_side_stiff) [expr {$ob(adap_side_stiff) - $stiff_alpha \
	* $ob(adap_stiff_range) * $stiff_metric48}]

    # bracket
    if {$ob(adap_side_stiff) < $ob(adap_min_stiff)} {
	set ob(adap_side_stiff) $ob(adap_min_stiff)
    }
    if {$ob(adap_side_stiff) > $ob(adap_max_stiff)} {
	set ob(adap_side_stiff) $ob(adap_max_stiff)
    }

    puts "after slot $mob(hits): adjust slottime [f3 $ob(slottime)] side_stiffness [f3 $ob(adap_side_stiff)]"
    puts $ob(adap_log_fd) "after slot $mob(hits): adjust slottime [f3 $ob(slottime)] side_stiffness [f3 $ob(adap_side_stiff)]"

    if {$ob(planar)} {
	wshm side_stiff $ob(adap_side_stiff)
    }
    if {$ob(planarhand)} {
	wshm side_stiff $ob(adap_side_stiff)
    }
    if {$ob(wrist)} {
	wshm wrist_diff_side_stiff $ob(adap_side_stiff)
    }

    if {$ob(planarwrist)} {
	# puts "planerwrist test after adjust"
	wshm side_stiff $ob(adap_side_stiff)
	set ob(adap_wrist_diff_side_stiff) [expr {$ob(adap_wrist_diff_side_scale) * $ob(adap_side_stiff)}]
	wshm wrist_diff_side_stiff $ob(wrist_diff_side_stiff)
	puts "adap_wrist_diff_side_stiff [f3 $ob(adap_wrist_diff_side_stiff)]"
	puts $ob(adap_log_fd) "adap_wrist_diff_side_stiff [f3 $ob(adap_wrist_diff_side_stiff)]"
    }

    ctreset npoints48
    ctreset stiff_metric48
    ctreset speed_metric48
}

# radians to degrees
proc rad_to_deg {r} {expr {$r * 45. / atan(1.)}}

# this code gets run to display performance metrics
# the code that invokes it is somewhat subtle, because it needs
# to stop the blink loop in an unusual way.

# most of the time, upon calling ballEnter (when you enter a target ball),
# it immediately schedules the next ball.  In this case, we call pm_display
# instead, without scheduling the next ball yet.  we have to roll back the
# mob(hits) count and do some other funny business, to make sure that
# we can continue cleanly and that tasks happen at the correct times.
# (see ballEnter)

proc pm_display {} {
    global ob mob
    # stop the game

    # mob(hits) has been decremented already
    set npoints [ctget npoints80]
    set init [ctget initiate]
    ctreset initiate
    set active_power [ctget active_power80 -avgn]
    set robot_power [ctget robot_power80 -avgn]
    set min_jerk_deviation [ctget min_jerk_deviation80 -avgn]
    set min_jerk_dgraph [ctget min_jerk_dgraph80 -avgn]
    set jerkmag [ctget jerkmag80 -avgn]
    set jerkdiv [ctget jerkdiv80 -avgn]
    set dist_straight_line_sq [ctget dist_straight_line_sq80 -avgn]
    set max_dist_along_axis [ctget max_dist_along_axis80 -avgn]
    set min_dist_from_target [ctget min_dist_from_target80 -avgn]

    if {$ob(slotnum) == 0} return

    set pmv2_init [expr {80 - $init}]
    set init [expr {100.0 * $init / 80}]
    set av_slotlength $ob(slotlength)
# puts "in pm_display ob(slotlength) $ob(slotlength)"
    # average of .48x.24 football lengths
    if {$ob(wrist)} {
	set av_slotlength .37
    }
    # .56 radians == 32 degrees
    if {$ob(wrist_ps)} {
	set av_slotlength .56
    }
# dtime "pm_display av_slotlength $av_slotlength"
    if {$ob(wrist_ps) || $ob(wrist)} {
	set mdaa [expr {$max_dist_along_axis / $av_slotlength}]
	set max_dist_along_axis [expr {int([rad_to_deg $mdaa])}]
	set pmv2_min_dist_from_target [expr {int([rad_to_deg $min_dist_from_target])}]
    } else {
	set max_dist_along_axis [expr {100.0 * $max_dist_along_axis / $av_slotlength}]
	set pmv2_min_dist_from_target [expr {int(1000. * $min_dist_from_target)}]
    }
    # active power:
    # 1.875 * .14 / 3
    # 1.875 * slotlength / slottime
    # yields about -2 watts
    # force 200 N/m * .14 yields 28 N.
    # * -50 yields range of 0 to 100.
    if {$ob(wrist) || $ob(wrist_ps)} {
	set active_power [expr {100.0 - ($active_power * -400.)}]
	set pmv2_active_power [expr {int($active_power * 1000.)}]
	set pmv2_robot_power [expr {int($robot_power * 1000.)}]
    } else {
	set active_power [expr {100.0 - ($active_power * -100.)}]
	set pmv2_active_power [expr {int($active_power * 1000.)}]
	set pmv2_robot_power [expr {int($robot_power * 1000.)}]
    }
    set min_jerk_deviation [expr {100. - (6.25 * 100.0 * $min_jerk_deviation)}]
    set pmv2_min_jerk_dgraph [expr {int(1000. * $min_jerk_dgraph)}]
    set pmv2_jerkmag [expr {int($jerkmag)}]
    # scale wrist jerkmag, it gets too big.
    if {$ob(wrist_ps) || $ob(wrist)} {
	set pmv2_jerkmag [expr {int($jerkmag / 100.)}]
    }
    set pmv2_jerkdiv [expr {int($jerkdiv)}]
# dtime "min_jerk_dgraph before scaling $min_jerk_dgraph"
    if {$ob(wrist)} {
	if {$ob(wrist_ps)} {
	    # set min_jerk_dgraph [expr {20.0 + 1500. * ($min_jerk_dgraph -0.34)}]
	    set min_jerk_dgraph [expr {100. - (150. * ($min_jerk_dgraph))}]
	    set rootdsl [expr {sqrt($dist_straight_line_sq)}]
	    set pmv2_dist_straight_line [expr {int([rad_to_deg $rootdsl])}]
	    set dist_straight_line [expr {100. - (50. * 10.0 * sqrt($dist_straight_line_sq))}]
	} else {
	    set min_jerk_dgraph [expr {100. - (2000. * $min_jerk_dgraph)}]
	    set rootdsl [expr {sqrt($dist_straight_line_sq)}]
	    set pmv2_dist_straight_line [expr {int([rad_to_deg $rootdsl])}]
	    set dist_straight_line [expr {100. - (50. * 10.0 * sqrt($dist_straight_line_sq))}]
	}
    } else {
	set min_jerk_dgraph [expr {100. - (6.25 * 100.0 * $min_jerk_dgraph)}]
	set pmv2_dist_straight_line [expr {int(1000 * sqrt($dist_straight_line_sq))}]
	set dist_straight_line [expr {100. - (50. * 100.0 * sqrt($dist_straight_line_sq))}]
    }

    # puts "\npm display:"
    # puts "slotnum $ob(slotnum)"
    # puts "init $init"
    # puts "max_dist_along_axis $max_dist_along_axis"
    # puts "active_power $active_power"
    # puts "min_jerk_deviation $min_jerk_deviation"
    # puts "dist_straight_line $dist_straight_line"

    # logfile
    puts $ob(adap_log_fd) "\npm display:"
    puts $ob(adap_log_fd) "slotnum $ob(slotnum)"
    puts $ob(adap_log_fd) "init $pmv2_init"
    puts $ob(adap_log_fd) "min_dist_from_target $pmv2_min_dist_from_target"
    puts $ob(adap_log_fd) "robot_power $pmv2_robot_power"
    puts $ob(adap_log_fd) "jerkmag $pmv2_jerkmag"
    # puts $ob(adap_log_fd) "jerkdiv $pmv2_jerkdiv"
    puts $ob(adap_log_fd) "dist_straight_line $pmv2_dist_straight_line"
    flush $ob(adap_log_fd)

    # fn2 is created at the end of every 80
    # fn4 is appended at the end of every 80, for final graph report.
    set pid [pid]

    puts "init $pmv2_init mdft $pmv2_min_dist_from_target rp $pmv2_robot_power \
	jerk $pmv2_jerkmag mdsl $pmv2_dist_straight_line"

    set fn2 "/tmp/clock_pm2_$pid.asc"
    set fd2 [open "$fn2" w]
    puts $fd2 "init $pmv2_init mdft $pmv2_min_dist_from_target rp $pmv2_robot_power \
	jerk $pmv2_jerkmag mdsl $pmv2_dist_straight_line"
    close $fd2

    set fn4 "/tmp/clock_pm4_$pid.asc"
    # append
    set fd4 [open "$fn4" a]
    puts $fd4 "init $pmv2_init mdft $pmv2_min_dist_from_target rp $pmv2_robot_power \
	jerk $pmv2_jerkmag mdsl $pmv2_dist_straight_line"
    close $fd4

    if {$mob(hits) > 300} {
	# save clock_pm4 to be displayed on next run
	# only if it's not wrist adaptive_ps
	if {![regexp "adaptive_ps" $ob(gamename)]} {
	    file copy -force $fn4 $ob(logdirbase)/$ob(patname)/clock_pm4.asc
	}
	# exec ./gppm2.tcl $fn4 > /dev/tty &
	exec ./gppm2.tcl $fn4 &
	after 500 set ::tksleep_end 1
	vwait ::tksleep_end
	# file delete [glob /tmp/clock_pm4.asc]
    }

    # this one should be on top of the fn4
    # exec ./gppm2.tcl $fn2 > /dev/tty &
    exec ./gppm2.tcl $fn2 &
    after 500 set ::tksleep_end 1
    vwait ::tksleep_end
    file delete [glob /tmp/clock_pm2*.asc]
}

proc change_contrast {} {
    global ob
    # set ob(ball,col,1) #cc0000
    set ob(ball,col,2) #ffcccc
}

proc print_pm {} {
    global ob

    puts "clock.tcl performance metrics dump:"
    if {!$ob(adaptive)} {
	puts "no adaptive, no performance metrics."
	puts ""
	return
    }
    set npoints [ctget npoints80]
    set init [ctget initiate]
    set max_dist_along_axis [ctget max_dist_along_axis80 -avg]
    set active_power [ctget active_power80 -avg]
    set min_jerk_dgraph [ctget min_jerk_dgraph80 -avg]
    set dist_straight_line_sq [ctget dist_straight_line_sq80 -avg]

    set init [expr {100.0 * $init / $ob(slotnum)}]
    set max_dist_along_axis [expr {100.0 * $max_dist_along_axis / 0.14}]
    # active power:
    # 1.875 * .14 / 3
    # 1.875 * slotlength / slottime
    # yields about -2 watts
    # force 200 N/m * .14 yields 28 N.
    # * -50 yields range of 0 to 100.
    set active_power [expr {100.0 - ($active_power * -100.)}]
    set min_jerk_dgraph [expr {100. - (6.25 * 100.0 * $min_jerk_dgraph)}]
    set dist_straight_line [expr {100. - (50. * 100.0 * sqrt($dist_straight_line_sq))}]

    puts "npoints: $npoints"
    puts "1 $init 2 $max_dist_along_axis 3 $active_power \
	4 $min_jerk_dgraph 5 $dist_straight_line"
    puts ""
}

# init adaptive variables

proc init_adap {} {
    global ob
    # dtime "calling init_adap"

    # TODO: split out for 5d
    set ob(adap_stiff_range) [expr {$ob(adap_max_stiff) - $ob(adap_min_stiff)}]
    set ob(adap_time_range) [expr {$ob(adap_max_time) - $ob(adap_min_time)}]

    # adap_slot_metrics metrics
    ctinit active_power16 -lastn 16
    ctinit robot_power16 -lastn 16
    ctinit min_jerk_deviation16 -lastn 16
    ctinit min_jerk_dgraph16 -lastn 16
    ctinit dist_straight_line_sq16 -lastn 16
    ctinit max_dist_along_axis16 -lastn 16
    ctinit min_dist_from_target16 -lastn 16
    ctinit active_power_metric16 -lastn 16
    ctinit min_jerk_metric16 -lastn 16
    ctinit min_jerk_dgmetric16 -lastn 16
    ctinit speed_metric16 -lastn 16
    ctinit stiff_metric16 -lastn 16

    # adjust_adap_controller metrics
    ctinit speed_metric48 -lastn 48
    ctinit stiff_metric48 -lastn 48
    ctinit npoints48 -lastn 48

    ctinit speed_performance_level3 -lastn 3
    ctinit stiff_performance_level3 -lastn 3

    # pm_display metrics
    # ctinit initiate -lastn 80
    ctinit initiate
    ctinit max_dist_along_axis80 -lastn 80
    ctinit min_dist_from_target80 -lastn 80
    ctinit active_power80 -lastn 80
    ctinit robot_power80 -lastn 80
    ctinit min_jerk_deviation80 -lastn 80
    ctinit min_jerk_dgraph80 -lastn 80
    ctinit jerkmag80 -lastn 80
    ctinit jerkdiv80 -lastn 80
    ctinit dist_straight_line_sq80 -lastn 80
    ctinit npoints80 -lastn 80

    if {$ob(planar)} {
	wshm side_stiff $ob(adap_side_stiff)
    }
    if {$ob(planarhand)} {
	wshm side_stiff $ob(adap_side_stiff)
    }
    if {$ob(wrist) && ! $ob(wrist_ps)} {
	set ob(adap_side_stiff) $ob(wrist_diff_side_stiff)
	wshm wrist_diff_side_stiff $ob(adap_side_stiff)
    }
    if {$ob(planarwrist)} {
	wshm side_stiff $ob(adap_side_stiff)
	set ob(adap_wrist_diff_side_stiff) [expr {$ob(adap_wrist_diff_side_scale) * $ob(adap_side_stiff)}]
	wshm wrist_diff_side_stiff $ob(adap_wrist_diff_side_stiff)
    }

    wshm pm_npoints 0

    set tailname [file tail $ob(gamename)]
    set filename [join [list $tailname $ob(timestamp)] _]
    set filename [file join $ob(dirname) $filename]
    file mkdir $ob(dirname)
    set ob(adap_log_fd) [open "${filename}.asc" w]
    puts $ob(adap_log_fd) "dir: $ob(dirname)"
    puts $ob(adap_log_fd) "game: $tailname"
    puts $ob(adap_log_fd) "time: $ob(timestamp)"
    puts $ob(adap_log_fd) "slot length: $ob(slotlength)"
    puts $ob(adap_log_fd) "starting slottime: [f3 $ob(slottime)]"
    puts $ob(adap_log_fd) "starting stiffness: [f3 $ob(adap_side_stiff)]"
    flush $ob(adap_log_fd)

}

# zero performance metrics

proc adap_zero_pm {} {
    global ob slot_done
# dtime "adap_zero_pm"
    wshm pm_active_power 0.0 ;# pm2a
    wshm pm_robot_power 0.0 ;# pm2a
    wshm pm_min_jerk_deviation 0.0 ;# pm2b
    wshm pm_min_jerk_dgraph 0.0 ;# pm2b
    wshm pm_jerkmag 0.0 ;# pm2b
    wshm pm_max_vel 0.0
    wshm pm_dist_straight_line 0.0 ;# pm3
    wshm pm_max_dist_along_axis 0.0 ;# pm4
    wshm pm_min_dist_from_target 10.0 ;# new pm4
    wshm pm_npoints 0
    wshm hand_active_power 0.0
    wshm hand_npoints 0
    if {[info exists slot_done]} {
	unset slot_done
    }
}

# a normal movebox, except for the adaptive case.
# for adaptive, open a static box first, then move it.

proc clock_movebox {forlist src dest} {
    global ob

    set forlist [uplevel 1 [list subst -nocommands $forlist]]
    set src [uplevel 1 [list subst -nocommands $src]]
    set dest [uplevel 1 [list subst -nocommands $dest]]

    status_mes "start clock_movebox" $ob(sm_movebox)
    # these only have x/y, they need w/h

    lappend src 0.0 0.0
    lappend dest 0.0 0.0

    if {$ob(linear)} {
	set ob(hdir) 1
	set src [eval swaps $src]
	set dest [eval swaps $dest]
    }

    if {!$ob(adaptive) || $ob(kvlim_wait) <= 0.0} {
	# if not adaptive, a simple movebox.
# dtime "simple clock_movebox 0 $ob(controller) {$forlist} {$src} {$dest}"
	movebox 0 $ob(controller) $forlist $src $dest
	set ob(mb_state) movebox
	return
    }

    # adaptive...

    # zero the pm counters
    adap_zero_pm

    if {$ob(collapse)} {
	set src [point_to_collapse $src $dest]
    }

    # a stationary slot immediately
    # movebox 0 4 {0 1 0} $src $dest
# dtime "adaptive clock_movebox stationary slot ($src) ($dest)"
    movebox 0 $ob(controller) {0 1 0} $src $dest
    set ob(mb_state) open_slot
    clock_beep 3

# two different moveboxes.
# keep track of number of times vlim is hit.

    # if we get a vlim event, this happens early.
    set ob(mb2_after_id) [after $ob(kvlim_wait) \
	    [list clock_movebox2 0 $ob(controller) $forlist $src $dest]]
}

# cancel movebox timeouts.  these are timeouts that occur *during*
# a slot, and they can be cancelled *during* a slot.
# we don't want to cancel do_slot_timeout with this.

proc cancel_mb_timeouts {} {
    global ob
# dtime "cancel mb timeouts"

    if {[info exists ob(pre_wait_after_id)]} {
	after cancel $ob(pre_wait_after_id)
	unset ob(pre_wait_after_id)
    }

    if {[info exists ob(mb2_after_id)]} {
	after cancel $ob(mb2_after_id)
	unset ob(mb2_after_id)
    }
}

# this is called when the movebox for clock_movebox2 times out,
# also called if the patient hits the target first.
# harvest most metrics here, rather than waiting for a long timeout

proc clock_movebox2_done {cause} {
    global slot_done ob

# dtime "clock_movebox2_done $cause"

    # slot_done exists, because patient took too long
    if {[info exists slot_done]} {
	 return
    }

    if {[info exists ob(mb2_done_after_id)]} {
	after cancel $ob(mb2_done_after_id)
	unset ob(mb2_done_after_id)
    }

    if {$cause == "timeout"} {
	clock_beep 6
    }

    status_mes "clock_movebox2_done $cause" $ob(sm_movebox)
    # speed metric
    # read from ctlr
    set slot_done(npoints) [rshm pm_npoints]
    set slot_done(active_power) [rshm pm_active_power]
    set slot_done(robot_power) [rshm pm_robot_power]
    set slot_done(min_jerk_deviation) [rshm pm_min_jerk_deviation]
    set slot_done(min_jerk_dgraph) [rshm pm_min_jerk_dgraph]
    set slot_done(jerkmag) [rshm pm_jerkmag]
    set slot_done(max_vel) [rshm pm_max_vel]
    set slot_done(dist_straight_line_sq) [rshm pm_dist_straight_line]
    set slot_done(maxdist) [rshm pm_max_dist_along_axis]
    set slot_done(mindist) [rshm pm_min_dist_from_target]

    # for testing  with tools/display
    wshm done_npoints $slot_done(npoints)
    wshm done_active_power $slot_done(active_power)
    wshm done_robot_power $slot_done(robot_power)
    wshm done_min_jerk_deviation $slot_done(min_jerk_deviation)
    wshm done_min_jerk_dgraph $slot_done(min_jerk_dgraph)
    wshm done_jerkmag $slot_done(jerkmag)
    wshm done_max_vel $slot_done(max_vel)
    wshm done_dist_straight_line_sq $slot_done(dist_straight_line_sq)
    wshm done_max_dist_along_axis $slot_done(maxdist)
    wshm done_min_dist_from_target $slot_done(mindist)

# parray slot_done
}

# delete the mb2_after_id, cancel the event, and execute.
proc clock_movebox2 {id ctlr forlist src dest} {
    global ob

    # don't cancel do_slot_timeout here!
    cancel_mb_timeouts
    if {$ob(adap_patient_moved)} {
# dtime "clock_movebox2 patient moved"
	clock_beep 5
	set cause moved
    } else {
# dtime "clock_movebox2 patient did not move"
	clock_beep 6
	set cause timeout
    }


# zero adap timers right before adaptive movebox, throwing away the stuff
# accumulated before the patient moves (or doesn't)
    adap_zero_pm

# dtime "adap clock_movebox2 movebox $id $ctlr ($forlist) ($src) ($dest)"
    status_mes "clock_movebox2_start $cause" $ob(sm_movebox)
    movebox $id $ctlr $forlist $src $dest
    set ob(mb_state) movebox

    # set timer to collect pm stats at end of move (before stiffen)
    # don't collect during stiffen and wait, or during hand robot wiggling
    set donems [expr {[lindex $forlist 1] * 1000 / $ob(Hz)}]
    set ob(mb2_done_after_id) [after $donems clock_movebox2_done timeout]
# dtime "adap clock_movebox2 set ob(mb2_done_after_id) after $donems clock_movebox2_done timeout"

}

# adaptive metrics at the end of a slot.

# note re ob(just_ran_pm_display):
# the ob(just_ran_pm_display) flag is a workaround.
# it corrects some kinks, but it should really be debugged and removed.

proc enter_target_do_adaptive {cause} {
    global ob mob

    if {!$ob(adaptive)} {return}

    # for running tests that look like adaptive
    if {$ob(no_metrics)} {return}

    # the center ball is 0
# dtime "enter_target_do_adaptive cause $cause hits $mob(hits) slotnum $ob(slotnum)"

    if {[info exists ob(mb2_done_after_id)]} {
	after cancel $ob(mb2_done_after_id)
	unset ob(mb2_done_after_id)
	clock_movebox2_done hit
    }
    # every slot
    adap_slot_metrics
    # every per circuit (16 slots)
    if {($mob(hits) % 16) == 0} {
	adap_circuit_metrics

	set circnum [expr {$mob(hits) / 16}]
	# adjust after n circuits, note that this switch
	# is only called 1x per circuit because of hits%16 just above.
	switch -- $circnum {
	1 -
	2 -
	3 -
	4 -
	5 -
	8 -
	11 -
	14 -
	17 { adjust_adap_controller }
	default {}
	}

	# Planar wrist does pm display as part of its state machine
	if {$ob(planarwrist)} {
	    return
	}

	# pm_display every 5 circuits
	switch -- $circnum {
	5 -
	10 -
	15 -
	20 {
	    if {!$ob(just_ran_pm_display)} {
		set ob(just_ran_pm_display) yes
		pause_target
		after 200 pm_display
		set ob(score) "$mob(hits)/$ob(nslots)"
		if {$ob(grasp_pick_game)} {
		    set ob(grasp_score_str) "$ob(grasp_score)/$mob(hits)"
		}
		return
	    }
	}
	default {}
	}

	# if we have kid images, draw new ones once per circuit.
        draw_new_images
    }
}


# slot timed out before patient reached target.

proc do_slot_timeout {} {
    global ob

clock_beep 4

    # should we pause?
    if {$ob(timeoutpause)} {
	# pause, as though therapist hit a space.
	pause_target
    } else {
	enter_target_ball slot_timeout
	if {!$ob(just_ran_pm_display)} {
	    set ballid $ob(ball,$ob(ball,next,dir),id)
	    leave_target_ball $ballid $ob(bigcan) slot_timeout
	}
    }
}

proc color_ball {color ball} {
    global ob
    set w $ob(bigcan)

# dtime "color_ball $color $ball"

    set wid 5
    if {$color == "off" } {
	set wid 0
	set color "black"
    }
    if {$ob(draw_animals) || $ob(draw_1012)} {
	$w itemconfigure $ball -outline $color -width $wid
    } else {
	$w itemconfigure $ball -fill $color
    }
}

# first trip through circuit

proc init_target {} {
    global ob mob

    # later...
    # if {$ob(linear)} {return}

    set w $ob(bigcan)

    set ob(ball,this,dir) C
    set ob(ball,this,id) $ob(ball,C,id)
    if {$ob(nballs) == 0} {
	set ob(ball,next,dir) C
	set ob(ball,next,id) $ob(ball,C,id)
    } else {
	if {$ob(wrist_ps)} {
	    set ob(ball,next,dir) E
	    set ob(ball,next,id) $ob(ball,E,id)
	} elseif {$ob(wrist_fe)} {
	    set ob(ball,next,dir) E
	    set ob(ball,next,id) $ob(ball,E,id)
	} else {
	    set ob(ball,next,dir) N
	    set ob(ball,next,id) $ob(ball,N,id)
	}
    }

    # when the wrist is paused, it is sending forces to the motors
    # to hold up the handle.  10 min time out to make sure the motors
    # don't overheat.
    if {$ob(wrist)} {
	after 600000 clock_exit
    }

    # color_ball white $ob(ball,this,id)
    color_ball white $ob(ball,this,dir)

    status_mes [imes "Press Space Bar to Start"]
}

# therapist hit the space bar.
# or the program wants you to think that happened.
# stop slot if ball is blinking

proc pause_target {} {
    global ob mob
    set w $ob(bigcan)

    blinkstop $w
# dtime "pause_target white, blinking $ob(blinking)"
    # color_ball white $ob(ball,next,id)
    if {$ob(static)} {
       color_ball white C
    } else {
       color_ball white $ob(ball,next,dir)
    }

    # when the wrist is paused, it is sending forces to the motors
    # to hold up the handle.  10 min time out to make sure the motors
    # don't overheat.
    if {$ob(wrist)} {
	after 600000 clock_exit
    }

    # when you pause, there may not yet be a collapsing slot.
    # if so, move to the target ball.
    # these states are only for adaptive.
    if {"$ob(mb_state)" == "pre_wait" || "$ob(mb_state)" == "open_slot"} {
	    set src $ob(ball,$ob(ball,this,dir),center)
	    lappend src 0.0 0.0
	    set dest $ob(ball,$ob(ball,next,dir),center)
	    lappend dest 0.0 0.0
	    movebox 0 $ob(controller) {0 400 1} $src $dest
    }
    set ob(mb_state) paused

    hand_grasp_cancel

    if {$ob(grasp_squeeze_game)} {
	$w itemconfig grasp_squeeze_cursor -state hidden
	$w itemconfig grasp_squeeze_target -state hidden
	indarrow_hide $w

	# set hand_collapse_save $ob(hand_collapse)
	# set ob(hand_collapse) yes
	# hand_grasp_open_slot
	# if {$ob(grasp_state) == "closed"} {
	    # hand_grasp_close
	# } else {
	    # hand_grasp_open
	# }
	# after 200 set ::ob(hand_collapse) $hand_collapse_save
    }

    if {$ob(grasp_pick_game) && $ob(grasp_state) == "closed"} {
	hand_grasp_open
    }
    if {$ob(grasp_reach_game) && $ob(grasp_state) == "closed"} {
	hand_grasp_open
    }

    if {$ob(grasp_pick_game)} {
	after 100 grasp_pick_hide_token $::ob(bigcan)
	indarrow_hide $w
    }

    adap_stiff_adjust pause

    if {!$ob(just_ran_pm_display)} {
	enter_target_ball pause
    }

    status_mes [imes "Press Space Bar to Start"]
}

# start slot if ball is white (and not blinking)

proc unpause_target {} {
    global ob
    set w $ob(bigcan)

    # wrist sets 10 min exit timeout
    if {$ob(wrist)} {
	after cancel clock_exit
    }

    # make sure planar handle is near start point before unpausing
    if {($ob(planar) || $ob(planarhand))
	    && ($ob(nballs) != 0)
	    && (!$ob(grasp_squeeze_game))} {
	set actx [rshm x]
	set acty [rshm y]
	if {$::mob(hits) == 0} {
	    set nextdir C
	} else {
	    set nextdir $ob(ball,next,dir)
	}
	foreach {startx starty} $ob(ball,$nextdir,center) break
	set len [expr {abs(hypot($acty-$starty,$actx-$startx))}]
	if {$len > .05} {
	    status_mes "Please move yellow cursor to white ball before you start."
	    return
	}
    }

# changed this so stop movebox before slot only if there are no motor forces
    if {!$ob(motorforces)} { stop_movebox 0 }
    if {$ob(planarhand_grasp_games) && !$ob(motorforces)} {
	stop_movebox 1
    }

    if {$ob(grasp_squeeze_game)} {
        incr ob(next_squeeze_target_number)
        wshm targetnumber $ob(next_squeeze_target_number)
	$w itemconfig grasp_squeeze_cursor -state normal
	$w itemconfig grasp_squeeze_target -state normal
        if {$ob(grasp_indicate) == "close"} {
            hand_arrow $w 0 0 last
            indarrow_show $w
            hand_grasp_open
        } else {
            hand_arrow $w 0 0 first
            indarrow_show $w
            hand_grasp_close
        }
    }

    # simulate leave target
    set ballid $ob(ball,$ob(ball,this,dir),id)
# dtime "unpause_target $ballid $ob(ball,this,dir)"
    leave_target_ball $ballid $ob(bigcan) unpause

    if {$ob(grasp_pick_game)} {
        indarrow_hide $w
    }

    set ob(blinking) yes
    blinkloop $w
    # it may have been set by pm_display
    set ob(just_ran_pm_display) no
    # don't allow pause on multilog games (playback static and ptp grasp)
    if {$ob(blinking) && $ob(log) && !$ob(logperslot)} {
        status_mes [imes "Space Bar not allowed for this task"]
    } else {
        status_mes [imes "Press Space Bar to Stop"]
    }
}

# stabilize pause by changing side_stiff to stiff
# set on pause_target
# unset on leave_target_ball

proc adap_stiff_adjust {{cause pause}} {
    global ob

    if {!$ob(adaptive)} return

    if {$cause == "pause"} {
	if {$ob(planar)} {
	    wshm side_stiff $ob(stiff)
	}
	if {$ob(planarhand)} {
	    wshm side_stiff $ob(stiff)
	}
	if {$ob(wrist)} {
	    wshm wrist_diff_side_stiff $ob(wrist_diff_stiff)
	}
	if {$ob(planarwrist)} {
	    wshm side_stiff $ob(stiff)
	    wshm wrist_diff_side_stiff $ob(wrist_diff_stiff)
	}
    } else {
	# set proper side stiffnesses, after enter_target_ball reset them
	if {$ob(planar)} {
	    wshm side_stiff $ob(adap_side_stiff)
	}
	if {$ob(planarhand)} {
	    wshm side_stiff $ob(adap_side_stiff)
	}
	if {$ob(wrist)} {
	    wshm wrist_diff_side_stiff $ob(adap_side_stiff)
	}
	if {$ob(planarwrist)} {
	    wshm side_stiff $ob(adap_side_stiff)
	    wshm wrist_diff_side_stiff $ob(adap_wrist_diff_side_stiff)
	}
    }
}

proc clock_space {} {
    global ob mob

    if {$ob(in_clock_exit)} {return}

    # don't allow pause on multilog games (playback static and ptp grasp)
    if {$ob(blinking) && $ob(log) && !$ob(logperslot)} {return}

    if {$ob(blinking)} {
# dtime "clock space pause"
	pause_target
    } else {
# dtime "clock space unpause"
	unpause_target
    }

}
# therapy is done, or therapist hit q to quit.
# stop logging, stop kernel module, and exit

set ob(in_clock_exit) no

proc clock_exit {} {
    global ob
    set ob(in_clock_exit) yes

    game_log_entry stopgame $ob(gamename)
    game_log_entry end $ob(gamename)

    # delete the /tmp/clock dir and all its contents
    # see tag_slotlength
    file delete -force /tmp/clock_path

    set w $ob(bigcan)
    # color_ball white $ob(ball,C,id)
    color_ball white $ob(ball,C,dir)

    if {$ob(grasp_games)} {
        stop_grasp
    }

    after cancel xyloop $w
    blinkstop $w
    update idletasks
    stop_log
    # wrist has anti-gravity even with !motorforces
    # if {$ob(wrist) && $ob(motorforces)}
    if {$ob(wrist)} {
	wdone
    }

    foreach i {0 1 2 3} {
	stop_movebox $i
        after 20
    }

    stop_rtl

    # give pm_display time to start
    if {$ob(just_ran_pm_display)} {
	after 2000 exit
    } else {
	exit
    }
}

# dump ob variables to stdout for debugging

proc dump_ob {} {
    global ob

    puts "clock.tcl ob dump:"
    parray ob
    puts ""
}

proc print_afters {} {
    puts "clock.tcl after event dump:"
    foreach i [after info] {
	puts "$i: [after info $i]"
    }
    puts ""
}

# start the clock!

main

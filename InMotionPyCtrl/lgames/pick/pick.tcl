#! /usr/bin/wish

# Copyright 2000-2013 Interactive Motion Technologies, Inc
# trb 9/2000

# pick up things
# added katakana/hiragana 3/2004
# added grasp 3/2004

# added animals 11/2005

# note that it only allows you to pick items that match
# the white menu button at the bottom.  other picks will be ignored.

# this controls whether we display japanese symbols.
set ob(pick_japanese) no

# animals?
set ob(pick_animals) no

source ../common/util.tcl
source ../common/menu.tcl

source $::env(I18N_HOME)/i18n.tcl

global ob

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

# is this planar or wrist?
localize_robot

    source ./kana.tcl

# for debugging
# no_arm

proc rancolor {} {
	set rainbow {red yellow green1 blue magenta}
	lindex $rainbow [irand 5]
}

package require Tk

global ob canvas

# made the scale bigger
# this makes the cursor move further per arm motion,
# because the pick screen now has more data on it.
set ob(scale) 3000.
set ob(tick) 50

#
# based on
# Example 34-2
# The canvas "Hello, World!" example.
#

# modified to drag multi-object items, with can,o.

proc CanvasMark {x y can} {
	global canvas otype mob ob
# puts "called CanvasMark $x $y $can"
	# Map from view coordinates to canvas coordinates
	set x [$can canvasx $x]
	set y [$can canvasy $y]
	# Remember the object and its location
	set obj [$can find overlapping $x $y $x $y]

	# the end one is the top one.
	set obj [lindex $obj end]

	# if we clicked on nothing
	if {$obj == {}} {
		arrayunset canvas
		return
	}

	if {![info exists ob(o_tag,$obj)]} return

	set canvas($can,x) $x
	set canvas($can,y) $y
	set canvas($can,o) $ob(o_tag,$obj)

	# if we are dragging this object set,
	# we want it on top of its neighbors.
	$can raise $canvas($can,o)

	if {[lsearch $otype($canvas($can,o)) $ob(bottombutton)] < 0} {
		array unset canvas
		# puts "$ob(bottombutton) no match"
		# errorblip $x $y
		return
	}

	# delete?
	if {$mob(del)} {
		$can delete $canvas($can,o)
		# dec the counts for the deleted object.
		foreach i $otype($canvas($can,o)) {
			incr mob($i) -1
		}
	}
}

proc CanvasDrag {x y can} {
	global canvas

	if {![array exists canvas]} return
	if {![info exists canvas($can,o)]} return
# puts "called CanvasDrag $x $y $can"
	# Map from view coordinates to canvas coordinates
	set x [$can canvasx $x]
	set y [$can canvasy $y]
	# Move the marked object
	set dx [expr $x - $canvas($can,x)]
	set dy [expr $y - $canvas($can,y)]
	$can move $canvas($can,o) $dx $dy
	set canvas($can,x) $x
	set canvas($can,y) $y 
}

proc errorblip {x y} {
	.c create oval [centxy $x $y 25] -tag errorblip -fill white
	after 100 .c delete errorblip
}


# animal images are from
# http://www.hasslefreeclipart.com/kid_animals/page1.html
# used under terms:
# http://www.hasslefreeclipart.com/pages_terms.html

# load the animal images once, so that we may use them later.

proc make_animals {} {
    global ob

    set ob(animal_list) {bird camel cow fish frog lion rooster turtle}
    foreach i $ob(animal_list) {
	set ob(animal,$i,imid) [image create photo -file animals/animals_$i.gif]
    }

    # for the menu at the bottom
    set i white_lion
    set ob(animal,$i,imid) [image create photo -file animals/animals_$i.gif]

}

proc gen1obj {n type typename color x1 y1 x2 y2 {bottom no}} {
	global ob mob otype

	# puts "gen1obj $n $type $typename $color $x1 $y1 $x2 $y2"

	# cell size
	set cells $ob(cells)
	set cells2 [expr {$cells / 2} ]
	# object size
	set obs [expr {$cells * 3 / 4} ]
	set obs2 [expr {$obs / 2} ]
	# line width
	set lw [expr {$obs / 5} ]
	# see above.
	set fn $ob(fnstr)
	set jfn $ob(jfnstr)

	set rx [expr {$x1 + $obs2}]
	set ry [expr {$y1 + $obs2}]

	# this switch list must be numerically contguous.
	# you can't ignore the animals and have the japanese
	# characters after it - if you want japanese and no animals,
	# renumber the list.  (should be fixed)

	switch $type {
		square -
		0 {	;# squares
			lappend otype(o_$n) square solid
			.c create rect \
			$x1 $y1 $x2 $y2 -fill $color \
			-tags [list o_$n obj]
			}
		osquare -
		1 {	;# outlined squares
			lappend otype(o_$n) square outline
			.c create rect \
			$x1 $y1 $x2 $y2 \
			-outline $color -width $lw \
			-tags [list o_$n obj]
			}

		circle -
		2 {	;# circles
			lappend otype(o_$n) circle solid
			.c create oval \
			$x1 $y1 $x2 $y2 -fill $color \
			-tags [list o_$n obj]
			}
		ocircle -
		3 {	;# outlined circles
			lappend otype(o_$n) circle outline
			.c create oval \
			$x1 $y1 $x2 $y2 \
			-outline $color -width $lw \
			-tags [list o_$n obj]
			}

		triangle -
		4 {	;# triangles
			lappend otype(o_$n) triangle solid
			.c create poly \
			$x1 $y2 $x2 $y2 $rx $y1 \
			-fill $color \
			-tags [list o_$n obj]
			}
		otriangle -
		5 {	;# outlined triangles
			lappend otype(o_$n) triangle outline
			.c create poly \
			$x1 $y2 $x2 $y2 $rx $y1 \
			-outline $color -width $lw \
			-tags [list o_$n obj]
			}

		plus -
		6 {	;# +'s
			lappend otype(o_$n) plus
			.c create line \
			$rx $y1 $rx $y2 -fill \
			$color -width $lw \
			-tags [list o_$n obj]
			.c create line \
			$x1 $ry $x2 $ry -fill \
			$color -width $lw \
			-tags [list o_$n obj]
			}

		ex -
		7 {	;# x's
			lappend otype(o_$n) ex
			.c create line \
			$x1 $y1 $x2 $y2 -fill \
			$color -width $lw \
			-tags [list o_$n obj]
			.c create line \
			$x1 $y2 $x2 $y1 -fill \
			$color -width $lw \
			-tags [list o_$n obj]
		}

		digit -
		8 {	;# digits (no zero or one)
			lappend otype(o_$n) digit
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			set digit [irand 8]; incr digit 2
			if {$bottom == "bottom"} {set digit 9}

			.c create text \
			$fx1 $fy1 -text $digit \
			-font $fn -fill $color \
			-tags [list o_$n obj]
			}

		lc -
		9 {	;# letters lc no ascenders/descenders
			lappend otype(o_$n) letter lc
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			set num [irand 10]
			set let [string index "acemnrsuvwz" $num]
			if {$bottom == "bottom"} {set let a}

			.c create text \
			$fx1 $fy1 -text $let \
			-font $fn -fill $color \
			-tags [list o_$n obj]
			}

		uc -
		10 {	;# letters uc
			lappend otype(o_$n) letter uc
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			set num [irand 10]
			set let [string index "ACEMNRSUVWZ" $num]
			if {$bottom == "bottom"} {set let A}

			.c create text \
			$fx1 $fy1 -text $let \
			-font $fn -fill $color \
			-tags [list o_$n obj]
			}

		animal -
		11 {
			lappend otype(o_$n) animal
			set anim [lindex $ob(animal_list) [irand 8]]
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			if {$bottom == "bottom"} {set anim white_lion}
			.c create image  \
			$fx1 $fy1 -image $ob(animal,$anim,imid) \
			-tags [list o_$n obj]
		}

		katakana -
		12 {	;# letters katakana
			global mini_kana kana_array
			lappend otype(o_$n) katakana
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			# get random number from nkana
			set num [irand 35]
			if {$bottom == "bottom"} {set num 0}
			# choose a kana
			set lname [lindex $mini_kana $num]
			set let $kana_array($lname)

			.c create text \
			$fx1 $fy1 -text $let \
			-font $jfn -fill $color \
			-tags [list o_$n obj]
			}

		hiragana -
		13 {	;# letters hiragana
			global mini_kana gana_array
			lappend otype(o_$n) hiragana
			set fx1 [expr {$x1 + $cells2}]
			set fy1 [expr {$y1 + $cells2}]
			# get random number from nkana
			set num [irand 35]
			if {$bottom == "bottom"} {set num 0}
			# choose a kana
			set lname [lindex $mini_kana $num]
			set let $gana_array($lname)

			.c create text \
			$fx1 $fy1 -text $let \
			-font $jfn -fill $color \
			-tags [list o_$n obj]
			}

		default {
			puts "gen1obj: default case, shouldn't get here."
			return
			}
	}

	# black bg square for easy clicking
	set bg [.c create rect $x1 $y1 $x2 $y2 -fill gray15 \
		-tags [list o_$n bg obj]]
	.c lower $bg

	# bottom should not have normal tags
	if {$bottom == "bottom"} {
		foreach o [.c find withtag o_$n] {
			.c dtag $o [.c gettags $o]
			.c addtag bottom withtag $o
		}
	}
}

# the list of shapes in the switch statement includes "o shapes"
# i.e., a hollow square instead of a solid square.
# this shape list does not have the hollow shapes.

    set ob(shapelist) {square circle triangle plus ex digit lc uc}
    set ob(longshapelist) {square osquare circle ocircle triangle otriangle plus ex digit lc uc}
if {$ob(pick_japanese)} {
    lappend ob(shapelist) katakana hiragana
    lappend ob(longshapelist) katakana hiragana
}
if {$ob(pick_animals)} {
    lappend ob(shapelist) animal
    lappend ob(longshapelist) animal
}

set ob(shapelen) [llength $ob(shapelist)]

proc incbottom {inc} {
	global ob

	set cells $ob(cells)
	set obs [expr {$cells * 3 / 4} ]
	set obs2 [expr {$obs / 2} ]
	set botx 0
	set boty $ob(totboardy2)

	set x1 [expr {$botx - $obs/2}]
	set x2 [expr {$botx + $obs/2}]
	set y1 [expr {$boty - $obs/2}]
	set y2 [expr {$boty + $obs/2}]

	set ob(bottomi) [expr {($ob(bottomi) + $inc) % $ob(shapelen)}]
	set ob(bottombutton) [lindex $ob(shapelist) $ob(bottomi)]
	set longi [lsearch $ob(longshapelist) $ob(bottombutton)]
	.c delete bottom
	gen1obj bottom $longi $ob(bottombutton) white $x1 $y1 $x2 $y2 bottom
	.disp config -textvariable mob($ob(bottombutton))
}

proc genbottombutton {} {
	global ob

	set cells $ob(cells)
	set obs [expr {$cells * 3 / 4} ]
	set obs2 [expr {$obs / 2} ]
	set botx 0
	set boty $ob(totboardy2)

	set x1 [expr {$botx - $obs/2}]
	set x2 [expr {$botx + $obs/2}]
	set y1 [expr {$boty - $obs/2}]
	set y2 [expr {$boty + $obs/2}]

	set ob(bottomi) 0
	set ob(bottombutton) [lindex $ob(shapelist) $ob(bottomi)]
	gen1obj bottom $ob(bottomi) $ob(bottombutton) white $x1 $y1 $x2 $y2 bottom
	.disp config -textvariable mob($ob(bottombutton))
}

# generate a new field of objects
proc genobjs {} {
	global ob mob otype

	# cell size
	set cells $ob(cells)
	set cells2 [expr {$cells / 2} ]
	# object size
	set obs [expr {$cells * 3 / 4} ]
	set obs2 [expr {$obs / 2} ]
	# line width
	set lw [expr {$obs / 5} ]
	# see above.
	set fn $ob(fnstr)
	set jfn $ob(jfnstr)

	# create a field of objects, i x j
	set n 0

        set ob(totboardx2) [expr {(10 * $cells + 2 * $obs) / 2}]
        set ob(totboardy2) [expr {(6 * $cells + 2 * $obs) / 2}]

	for {set j 1} {$j <= 5} {incr j} {
	for {set i 1} {$i <= 10} {incr i} {
		incr n
		set x1 [expr {$i * $cells - $ob(totboardx2)}]
		set x2 [expr {$x1 + $obs}]
		set y1 [expr {$j * $cells - $ob(totboardy2)}]
		set y2 [expr {$y1 + $obs}]

		set color [rancolor]

		set otype(o_$n) $color
		set ob($n,pos) [list $x1 $y1 $x2 $y2]

		# gen1obj includes the 3 hollow shapes,
		# see shapelist comment above.
		set type [irand [expr $ob(shapelen) + 3]]
		set typename [lindex $ob(longshapelist) $type]
		gen1obj $n $type $typename $color $x1 $y1 $x2 $y2

		# find the ids and index them by o_tag
		set ob($n,tag) [.c find withtag o_$n]
		foreach k $ob($n,tag) {set ob(o_tag,$k) o_$n}

		# bump the counts
		foreach o $otype(o_$n) { incr mob($o) }
	}}

	# cursor
	.c create oval [centxy .1 .1 .00625] -tag cursor -fill yellow -width 2
}

# delete objects
proc delobjs {} {
	global mob otype

	# everything except the character we maintain
	.c delete obj
	.c delete cursor

	foreach i {
		time
		solid outline
		square circle triangle
		plus ex
		digit letter lc uc
		katakana hiragana
		red yellow green1 blue magenta
		animal
	} {set mob($i) 0}
	arrayunset otype
}

proc restart {} {
	global ob env
        game_log_entry startgame

	delobjs
	genobjs
	genbottombutton
}

proc pick {} {
	global ob mob env

	set ob(programname) pick

        set ob(patname) [fnstring $env(PATID)]
        set ob(logdirbase) $env(THERAPIST_HOME)
        game_log_entry begin

        set ob(mainbg) black

	font create default -family Times -size -18
	option add *font default

        wm attribute . -zoomed 1
        update idletasks
        set ob(winwidth) [winfo width .]
        set ob(winheight) [winfo height .]
        set ob(winheight) [expr {$ob(winheight) - 30}]
        # set the cell size based on the screen size.
        # dmd got 9 by experiment.
        set ob(cells) [expr {int($ob(winheight) / 9)}]

	# deal with font naming, assume that if < 8, then QNX
	if {[tclvmaj] > 7} {
		set ob(fnstr) [list courier $ob(cells) bold]
		set ob(jcells) [expr {int($ob(cells) * .8)}]
		set ob(jfnstr) [list courier $ob(jcells) bold]
		set ob(jfnstr) [list mincho $ob(jcells) bold]
	} else {
		set ob(fnstr) {-adobe-courier-bold-r-normal-*-$ob(cells)-*-*-*-*-*-*-*}
	}

	# centers
	set ob(cx) [expr {$ob(winwidth) / 2}]
	set ob(cy) [expr {$ob(winheight) / 2}]
	# these are used by the debugging version of getptr
	set ob(half,x) $ob(cx)
	set ob(half,y) $ob(cy)

	make_animals

	canvas .c -width $ob(winwidth) -height $ob(winheight) -bg $ob(mainbg)
	# make the center be 0,0 - translate by "scrolling"
	.c config -scrollregion [list -$ob(cx) -$ob(cy) $ob(cx) $ob(cy)]
	.c config -highlightthickness 0

	set ob(bigcan) .c

if {$ob(pick_japanese)} {
	# we need one japanese character mapped at all times,
	# to keep the font cached. loading the 1st char takes 1 sec
	# instead of 30 usec for a normal char.
	# it's black on black and off bottom of the screen.
	.c create text 0 1000 -text $::gana_array(wa) \
		-font $ob(jfnstr) -tag cached
}

	catch {grid anchor . center}


	label .status -textvariable ob(status) -font default\
	-background $ob(mainbg) -foreground gray50
	status_mes [imes "Press n key for new set of symbols, Alt-m for menu"]

	grid .c
	grid .status

	wm geometry . 1000x675
	. config -bg $ob(mainbg)

	# new field
	bind . <n> restart
	bind . <Key-space> restart
	bind . <d> {global mob; set mob(del) [expr {!$mob(del)}]}

	bind . <Key-Right> {incbottom 1}
	bind . <Key-Left> {incbottom -1}

	# quit
	bind . <q> {done}
	bind . <Escape> {done}
        wm protocol . WM_DELETE_WINDOW { done }

	# for debugging, use mouse instead of robot.
	# .c bind obj <Button-1> {CanvasMark %x %y %W}
	# .c bind obj <B1-Motion> {CanvasDrag %x %y %W}

	bind .c <<GraspPress>> {CanvasMark %x %y %W}
	bind .c <<GraspMotion>> {CanvasDrag %x %y %W}

        set m [menu_init .menu]

	bind .menu <n> restart
	bind .menu <Key-space> restart

        menu_cb $m del "Click Deletes"
        # menu_t $m b1 "" ""

	menu_t $m solid Solid
	menu_t $m outline Outline
        # menu_t $m b2 "" ""

	menu_t $m square Square
	menu_t $m circle Circle
	menu_t $m triangle Triangle
        # menu_t $m b3 "" ""

	menu_t $m plus +
	menu_t $m ex X
        # menu_t $m b4 "" ""

	menu_t $m digit Digit
	menu_t $m letter Letter
	# menu_t $m lc Lowercase
	# menu_t $m uc Uppercase
if {$ob(pick_animals)} {
	menu_t $m animal Animal
}
if {$ob(pick_japanese)} {
	menu_t $m katakana Katakana
	menu_t $m hiragana Hiragana
}
        menu_t $m b5 "" ""

	# menu_t $m red Red
	# menu_t $m yellow Yellow
	# menu_t $m green1 Green
	# menu_t $m blue Blue
	# menu_t $m magenta Violet

	# unicode left and right arrow
        menu_t $m change "Change Symbol (\u2190/\u2192)" ""
        menu_t $m b6 "" ""

        menu_b $m restart "New Game (n)" restart
        menu_t $m menu "Toggle Menu (Alt-m)" ""
        menu_b $m quit "Exit (q)" {done}

	# start out with click deletes.
	set mob(del) 1

	start_rtl
	start_grasp .c

	set current_robot [current_robot]
	if {$current_robot != "planarhand"} {
		tk_messageBox -icon error -message "Warning: Pick game is supported only with planarhand robot configuration."
	}

	if {$ob(wrist)} {
		# hold ps at origin
		wshm wrist_diff_damp 0.0
		movebox 0 7 {0 1 0} {0. 0. 5. 5.} {0. 0. 5. 5.}
	}

	after 100

	label .disp -textvariable mob(square) -font $ob(scorefont) -bg $ob(mainbg) -fg yellow
	place .disp -in . -relx 1.0 -rely 0.0 -anchor ne

	# begin
	genobjs
	genbottombutton

	xyloop .c
}

# the cursor motion loop, runs 20x/sec
proc xyloop {w} {
    global ob

    # 20x / sec
    after $ob(tick) xyloop $w

    # get coords in world space meters
    set x [getptr x]
    set y [getptr y]

    if {$ob(wrist)} {
	foreach {x y} [wrist_ptr_scale $x $y] break
    }

    set ob(cur,x) $x
    set ob(cur,y) $y
    set ob(screen,x) [expr {int($x * $ob(scale)} + $ob(cx))]
    set ob(screen,y) [expr {int($y * -$ob(scale)} + $ob(cy))]

    # move the yellow cursor ball, scale, and flip its y
    $w coords cursor [centxy $x $y .004]
    # read and handle the grasp sensor
    grasp_iter $w

    $w raise cursor
    $w scale cursor 0 0 $ob(scale) [expr {-$ob(scale)}]
    # status_mes "x $x y $y cx $ob(screen,x) y $ob(screen,y)"
}

proc done {} {
	global ob env

        game_log_entry end [current_robot]

	stop_rtl
	exit
}

pick


# Copyright 2010-2013 Interactive Motion Technologies, Inc

# cons Game Console Report menu helper procs

proc consRptCalc { {dirname ""} } {
    global ob

    set dirlist [patlsdir $ob(tbasedir)]
    set calcnums [CBDialog_List "Calculate Reports" $dirlist]
    set dorecomp [lindex $calcnums 0]
    set calcnums [lrange $calcnums 1 end]
    if { $calcnums == "" } {
	return
    }

    set calclist ""
    foreach i $calcnums {
	set pat [lindex $dirlist $i]
	append calclist $pat " "
    }
    puts "running calc $calclist"
    eval exec $ob(pupsdir)/dopatgui.tcl $dorecomp $calclist > /dev/tty &
}

proc consRptShow { {dirname ""} } {
    global ob

    # get the patient names from the list of pdf files
    set pdflist [glob -tails -nocomplain -directory $ob(pdfs) reports_*pdf]

    foreach i $pdflist {
	regsub -- reports_\(.*\).pdf $i \\1 out
	set pdarr($out) 1
    }
    # assume that patient id's are numeric, so show most recent first
    set patlist [lsort -decreasing [array names pdarr]]

    set shownums [Dialog_List "Show Reports" $patlist]
    if { $shownums == "" } {
	return
    }

    set showglobs ""
    foreach i $shownums {
	set pat [lindex $patlist $i]
	append showglobs $ob(pdfs)/ reports_ $pat *pdf " "
    }
    set showlist [eval glob $showglobs]

    eval exec firefox [lsort $showlist] &
}

proc consRptCopy { {dirname ""} } {
	global ob
	exec thunar $ob(pdfs) &
}

proc consRptHelp { {bookmark "" } } {
    global ob

    switch [current_robot] {
	planar { set robtype arm }
	planarhand {set robtype arm }
	wrist {set robtype wrist }
	default {set robtype arm }
    }

    exec firefox file://$::env(CROB_HOME)/../man/$robtype.html\#$bookmark 2>/dev/null
}


#! /usr/bin/wish

# take a list of patients
# invoke dopats.tcl
# digest the text output from dopats and display it in a dialog box
# handle cancel request and try to kill dopats


package require Tk
source $::env(LGAMES_HOME)/pups/common.tcl

font create default -family Times -size -18
option add *font default

wm withdraw .

# a tk_messagebox, tweaked to suit
# remember, this blocks.

proc blockpop {str} {
    global mbanswer
    after 100 .__tk__messagebox.ok configure -state disabled
    after 100 .__tk__messagebox.msg configure -wraplength 5i
    set mbanswer [tk_messageBox -message $str -type okcancel]
    update idletasks
}

# change the message in the tk_messagebox

proc msgpop {str} {
    .__tk__messagebox.msg config -text $str
    update idletasks
}

# a one second loop. it updates the dialog message

proc sec_loop {} {
    global sec_loop_secs rptmsg pat patn argn ndates

    incr sec_loop_secs
    after 1000 sec_loop

    set nstr ""
    if {$argn > 1} {
        set nstr " ($patn/$argn)"
    }
    append mstr "Patient " $pat $nstr \n "$ndates Evaluation Sessions" \n $rptmsg \n "$sec_loop_secs seconds"

# keep it from changing the window size
    append mstr "\n                                                     "
    msgpop $mstr
}

proc got_a_line {} {
    global tickfd done rptmsg dopatpid pat
    gets $tickfd line
    if {$line == "done"} {
	# delete log on success
        file delete /tmp/talog/ta$dopatpid.log
        after cancel sec_loop
        .__tk__messagebox.ok configure -state normal
        .__tk__messagebox.ok invoke
    }
    if {$line == ""} {
        after cancel sec_loop
	# move/overwrite log on failure
        file rename -force /tmp/talog/ta$dopatpid.log $::env(HOME)/reports/raw_data/$pat/ta.log
        error "Report Calculation Failed."
        .__tk__messagebox.ok configure -state normal
        .__tk__messagebox.ok invoke
    }
    set rptmsg $line
}

proc can_all {} {
    global tickfd
    exec touch /tmp/cancel_report
    after cancel sec_loop
    catch {close $tickfd}
}

proc do1patgui {dorecomp arg} {
    global tickfd done rptmsg sec_loop_secs mbanswer pat ndates dopatpid
    file delete /tmp/cancel_report

    if {[is_lkm_loaded]} {
        bgerror "Robot game is running, please stop it before running reports."
        return cancel
    }

    set pat $arg
    set dates [glob -nocomplain $::env(THERAPIST_HOME)/$pat/eval/2???????_???]
    set ndates [llength $dates]

    set recompstr ""
    if {$dorecomp} {
	set recompstr "--nocache"
    }
    set tickfd [open "|$::env(LGAMES_HOME)/pups/dopatient.py $recompstr $pat" r]
    set dopatpid [pid $tickfd]

    set done 0
    set sec_loop_secs 0
    set rptmsg "..."

    fileevent $tickfd readable got_a_line

    after 1000 sec_loop
    set mbanswer ok
    blockpop "Start Patient Report Calculation"

    if {$mbanswer == "cancel"} {
        can_all
        return cancel
    } else {
        after cancel sec_loop
        catch {close $tickfd}
        return ok
    }
}

proc dopatgui {} {
    global argn patn ndates
    set ret ok
    set argn [llength $::argv]
    set patn 0
    set ndates 0
    if {$::argv == ""} {
        bgerror {usage: dopatgui.tcl patid [patid ...]}
        exit
    }

    if {[is_lkm_loaded]} {
        bgerror "Robot game is running, please stop it before running reports."
        exit
    }

    set dorecomp [lindex $::argv 0]
    set ::argv [lrange $::argv 1 end]
    foreach arg $::argv {
        incr patn
        set ret [do1patgui $dorecomp $arg]
        if {$ret == "cancel"} {
            break
        }
    }
    if {$ret == "cancel"} {
        after 2000 file delete /tmp/cancel_report
        after 3000 exit
    } else {
        # the afters are first, because blockpop blocks.
        # they have to be more than 100 because blockpup waits 100.
        # kludgy, but close enough.
        after 200 .__tk__messagebox.ok configure -state normal
        after 200 .__tk__messagebox.cancel configure -state disabled
        set str "Calculate Report Done.\n$::argv"
        blockpop $str
        exit
    }
}

dopatgui

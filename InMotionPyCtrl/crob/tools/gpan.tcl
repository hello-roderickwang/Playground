#! /usr/bin/tclsh
# Copyright 2004-2010 Interactive Motion Technologies, Inc
# trb 2/2004

# plot performance metrics

proc gpan {fn} {
    set tail [file tail $fn]
    set dname [file dirname $fn]

    set gp [open "|gnuplot -geometry 1000x735+5+5 -title $tail -persist" w]

    puts $gp "unset key"
    # puts $gp "set yrange \[0:100]"
    # puts $gp "set xrange \[0:6]"
    puts $gp "set grid"

    puts -nonewline $gp "plot '< $::env(CROB_HOME)/ta.tcl $fn' u 1:2 w l lw 3, "
    puts -nonewline $gp "'' u 1:3 w l lw 3"
    puts $gp ""
    flush $gp

    # todo: figure out titles
    close $gp
}

gpan [lindex $argv 0]

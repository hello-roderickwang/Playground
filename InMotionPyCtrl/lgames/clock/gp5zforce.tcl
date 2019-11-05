#! /usr/bin/tclsh

# shoulder plots

# Copyright 2004-2013 Interactive Motion Technologies, Inc
# trb 2/2004

# plot 8 directional x/y pos plots

# the other scripts have color choosing stuff.
# since these are all x/y, just use default red.

proc gp5zforce {fn {print screen}} {

    if {[string first "shoulder" $fn] < 0} {
	puts "gp5zforce: $fn is not a shoulder file"
	return
    }

    # puts "gp8 $fn"
    set dname [file dirname $fn]
    set tail [file tail $fn]

    set pat {^(\w+)_(\d{6})_(\d+).dat$}

    regexp $pat $tail full game time num

    # puts "full: $full"
    # puts "dname: $dname game: $game time: $time dir: $dir bt: $bt num: $num"

    set gp [open "|gnuplot -geometry 1000x675+5+5 -title $tail -persist" w]

    if [string match $print "print"] {
	puts $gp "set term post \"Helvetica\" 12"
	puts $gp "set output '/tmp/$tail.ps'"
    }

    puts $gp "set title \"${dname}/${game}_${time}\""
    puts $gp "set xlabel 'time (s)'"
    puts $gp "set ylabel 'z force (N)'"
    puts $gp "set xtics 1"
    puts $gp "set ytics 20"
    puts $gp "set yrange \[-80:80\]"
    puts $gp "set grid"

    puts -nonewline $gp "plot "
    foreach n {1 2 3 4 5} {
	set pfile "${dname}/${game}_${time}_$n.dat"
        if [file exists $pfile] {
	    if {$n != 1} {puts -nonewline $gp ","} 
	    puts -nonewline $gp "\"< $::env(CROB_HOME)/ta.tcl $pfile\" u (\$0/200):8 title \"$n\" with l lw 3"
	}
    }

    puts $gp ""

    puts $gp "set nomultiplot"
    # todo: figure out titles
    close $gp
    if [string match $print "print"] {
	exec ./pstoraw /tmp/$tail.ps
	file delete /tmp/$tail.ps
    }
}

gp5zforce [lindex $argv 0] [lindex $argv 1]

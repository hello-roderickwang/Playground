#! /usr/bin/tclsh
# mkcmds.tcl - make cmds.h for shm.c

# InMotion2 robot system software

# Copyright 2003-2013 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

# the command list needs to be initialized with the locations of the shared
# memory struct members, after they are alloc'd.  You can't do this variable
# init in the C declaration initializer, so here's a tcl script that pumps out
# the C code to do it at runtime.  This generates a .c source file that is, in
# turn, compiled.

# Note also that you can't store a variable expression in the cmd array.
# i.e., you can't say: cmds[0].loc = &ob->scr[i];
# and then alter the value of i at runtime, because the assignment to cmds
# happens only once.  if you want to walk down an array, you have to do it with
# "set/get array" code that takes the array base and index as separate args,
# and does the math by hand.  (Not yet written.)


source cmdlist.tcl

proc csetup {} {
    global cmdlist cmdarr cmdnum

    set j 0

    foreach i $cmdlist {
        foreach {type name loc size} $i break
        # check for dups
        if {[info exists cmdarr(i,$name)]} {
            puts stderr "mkcmds.tcl error: Duplicate entry in cmdlist.tcl: \
              $name"
            exit 1
        }
        set cmdarr(i,$name) $j
        set cmdarr(type,$j) $type
        set cmdarr(name,$j) $name
        set cmdarr(loc,$j) $loc
        set cmdarr(size,$j) $size
        incr j
    }
    set cmdnum $j
}

proc cprint {} {
    global cmdlist cmdarr cmdnum

    puts "// DO NOT EDIT THIS FILE!!!"
    puts "// it is created by mkcmds.tcl, see that script to recreate this \
      file.\n\n"

    puts "// InMotion2 robot system software\n"

    puts "// Copyright 2003-2013 Interactive Motion Technologies, Inc."
    puts "// Watertown, MA, USA"
    puts "// http://www.interactive-motion.com"
    puts "// All rights reserved\n\n"

    puts "enum {"
    puts "\tso_u8 = 0,"
    puts "\tso_u16,"
    puts "\tso_u32,"
    puts "\tso_u64,"
    puts "\tso_s8,"
    puts "\tso_s16,"
    puts "\tso_s32,"
    puts "\tso_s64,"
    puts "\tso_f32,"
    puts "\tso_f64,"
    puts "};\n\n"

    puts "struct cmd_s {"
    puts "\tu32 type;"
    puts "\ts8 *name;"
    puts "\tvoid *loc;"
    puts "\tu32 size;"
    puts "} cmds\[\] = {"
    for {set j 0} {$j < $cmdnum} {incr j} {
        puts "\t\{$cmdarr(type,$j), \"$cmdarr(name,$j)\", NULL, \
          $cmdarr(size,$j)\}, /* $j */"
    }
    puts "};\n\n"



    puts "void setcmdlocs(void) {"
    for {set j 0} {$j < $cmdnum} {incr j} {
        puts "\tcmds\[$j\].loc = $cmdarr(loc,$j);"
    }
    puts "}"
}

csetup
cprint
#!/bin/bash
# use sed to neaten up make output
# getting rid of long string options
# only on gcc lines
# especially for Linux kernel builds
#
# usage ./m
#
# gets rid of all -O* -D* -U* -I* -W*
# -i (-include)
# -f (-fomit* -fno-strict etc)
# -m (-malign*)
# -p (-pipe)
# -t (-traditional*)
#
# also changes multiple blanks to single.
#
# the idea isn't to get rid of every option, just to make the
# typical -c line come out neatly.
# getting rid of single letter options (like -E, -C -P)
# isn't as important
# 
# of course, you may tweak patterns to suit.
#
# sed -e '/gcc /s/-[ODIUWifmpt][^ ][^ ]* //g' -e 's/  */ /g'
#
# this one eats -??*

make | sed -e '/^[ke]*gcc /{s/-[^ ][^ ][^ ]* //g;s/  */ /g;}'

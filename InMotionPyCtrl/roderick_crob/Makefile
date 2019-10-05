# Makefile for Inmotion2 robot library

# InMotion2 robot system software

# Copyright 2003-2013 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

prefix := $(shell /usr/bin/xeno-config --prefix)

CWD = $(shell pwd)
UEI_INC = powerdaq/include

CC = $(shell /usr/bin/xeno-config --cc)
# TODO: remove -O0 in next line
CFLAGS = $(shell /usr/bin/xeno-config --skin=native --cflags) \
-I$(CWD)/../$(UEI_INC) \
-I. -g -O0 
LDFLAGS = $(shell /usr/bin/xeno-config --skin=native --ldflags) \
-lpowerdaq32 \
-lrtdm

ARCH = i386

# these are necessary to deal with trig functions (-lm)
# and hrtime math (libgcc.a)

MATHLIBS = -L/usr/lib -lm -lc `$(CC) -print-file-name=libgcc.a`
INCS = robdecls.h rtl_inc.h ruser.h uei_inc.h userfn.h pipes.h cmds.h

SRCS = main.c uei.o can.c fifo.c math.c \
	slot.c pci4e.c \
	pl_sensact.c pl_ulog.c pl_uslot.c \
	wr_sensact.c wr_ulog.c wr_uslot.c \
	an_sensact.c an_ulog.c an_uslot.c \
	ha_sensact.c ha_ulog.c ha_uslot.c

OBJS = main.o uei.o can.o fifo.o math.o \
	slot.o pci4e.o \
	pl_sensact.o pl_ulog.o pl_uslot.o \
	wr_sensact.o wr_ulog.o wr_uslot.o \
	an_sensact.o an_ulog.o an_uslot.o \
	ha_sensact.o ha_ulog.o ha_uslot.o

# default:

all: robot shm rwarp rtcansendmulti tools/refio atinetft mccd man

$(OBJS) : $(INCS)

robot: $(OBJS) $(INCS)
	$(CC) $(OBJS) $(LDFLAGS) -o robot $(MATHLIBS)

cmds.h: cmdlist.tcl
	tclsh mkcmds.tcl > cmds.out
	mv cmds.out cmds.h

shm: cmds.h shm.c $(INCS)
	$(CC) -Wall $(CFLAGS) -o shm shm.c

atinetft: atinetft.c $(INCS)
	$(CC) -Wall $(CFLAGS) -o atinetft atinetft.c

tools/refio: tools/refio.c $(INCS)
	$(CC) -Wall $(CFLAGS) -o tools/refio tools/refio.c

rwarp: rwarp.c $(INCS)
	$(CC) -Wall $(CFLAGS) -o rwarp rwarp.c -L/usr/X11R6/lib -lX11 -lXtst

rtcansendmulti: rtcansendmulti.c $(INCS)
	$(CC) -Wall $(CFLAGS) -o rtcansendmulti rtcansendmulti.c -lnative -lrtdm -lxenomai

mccd:
	cd ../mcc/c/; make

man:
	cd ../man/; make

clean:
	rm -f atinetft robot cmds.h cmds.out shm.o shm rwarp rtcansendmulti rwarp.o tools/refio tools/refio.o *\~ *\# $(OBJS)
	cd ../mcc/c/; make clean
	cd ../man/; make clean

# make a compiled tar for e.g. upgrade
# this is for IMT use only.
version: all
	tar -C /opt/imt -zcvf /tmp/$(shell basename $(shell dirname $(shell pwd -P))).tar.gz $(shell basename $(shell dirname $(shell pwd -P))) 

# clean, save, recompile
save: clean
	cd ..; tar zcvf ~/save/crob.tgz.`date +%m%d` crob
	make

install:
	echo "No install needed for crob."

distribute: all
	@read -p "WARNING: You are about to remove the source files. You will be unable to rebuild once you've done this. Enter to continue, Ctrl-C to abort." foo
	rm -f $(INCS) $(OBJS) $(SRCS)
	# hack for linear robot files and other non robot binary stuff
	rm -f li_*.c uei.c shm.c rwarp.c atinetft.c
	rm -rf ../uc
	rm -f /opt/imt/distro/robot4*.tar.gz
	rm -f /opt/imt/distro/bootstrap /opt/imt/distro/preseed.cfg


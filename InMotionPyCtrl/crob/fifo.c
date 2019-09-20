// fifo.c - perform i/o to real time fifos
// part of the robot.o robot process

// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"
#include "pipes.h"

// setup_fifos - create fifos for doing i/o between user mode
// and the robot control module.

void
init_fifos(void)
{
    int ret;
    static char ibuffer[FIFOLEN];

    // make sure they're not in use.
    cleanup_fifos();

#define POOLSIZE 16384

    // data input from user space
    ret = rt_pipe_create(&(ob->dififo), DIFIFO_NAME, DIFIFO_MINOR, POOLSIZE);
    if (ret < 0) {
        rob_log("%s:%d %s, %d return from rt_pipe_create()\n", __FILE__, __LINE__, __FUNCTION__, ret);
        cleanup_signal(0);
    }
    // data output to user space
    ret = rt_pipe_create(&(ob->dofifo), DOFIFO_NAME, DOFIFO_MINOR, POOLSIZE);
    if (ret < 0) {
        rob_log("%s:%d %s, %d return from rt_pipe_create()\n", __FILE__, __LINE__, __FUNCTION__, ret);
        cleanup_signal(0);
    }
    // error output to user space
    ret = rt_pipe_create(&(ob->eofifo), EOFIFO_NAME, EOFIFO_MINOR, POOLSIZE);
    if (ret < 0) {
        rob_log("%s:%d %s, %d return from rt_pipe_create()\n", __FILE__, __LINE__, __FUNCTION__, ret);
        cleanup_signal(0);
    }
    // tick data to user space
    ret = rt_pipe_create(&(ob->tcfifo), TCFIFO_NAME, TCFIFO_MINOR, POOLSIZE);
    if (ret < 0) {
        rob_log("%s:%d %s, %d return from rt_pipe_create()\n", __FILE__, __LINE__, __FUNCTION__, ret);
        cleanup_signal(0);
    }
    // fifo data to user space
    ret = rt_pipe_create(&(ob->ftfifo), FTFIFO_NAME, FTFIFO_MINOR, POOLSIZE);
    if (ret < 0) {
        rob_log("%s:%d %s, %d return from rt_pipe_create()\n", __FILE__, __LINE__, __FUNCTION__, ret);
        cleanup_signal(0);
    }
}

// clean up fifos created above

void
cleanup_fifos(void)
{
    int ret;

    ret = rt_pipe_delete(&(ob->dififo));
    ret = rt_pipe_delete(&(ob->dofifo));
    ret = rt_pipe_delete(&(ob->eofifo));
    ret = rt_pipe_delete(&(ob->tcfifo));
    ret = rt_pipe_delete(&(ob->ftfifo));
}

// li_ulog.c - linear robot user logging functions,
// to be modified by InMotion2 programmers
// part of the robot.o robot process
//
// InMotion2 robot system software

// Copyright 2005-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
// #include "uei_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

void
write_linear_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->linear.pos;
    ob->log[j++] = ob->linear.vel;
    ob->log[j++] = ob->linear.force;
    ob->log[j++] = rob->ft.world.x;
    ob->log[j++] = rob->ft.world.y;
    ob->log[j++] = rob->ft.world.z;

    // debug
    // ob->log[j++] = rob->linear.motor.volts;
    // ob->log[j++] = ob->slot[0].bcur.point.x;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
read_linear_fifo_sample_fn(void)
{
    s32 j;
    f64 i;
    s32 ret;

    if (ob->nrref < 1)
        return;

    ret = rt_pipe_read(&(ob->dififo), ob->refin, (sizeof(ob->refin[0]) * ob->nrref),
                       TM_NONBLOCK);
    j = 0;

    // if refin[0] is not integral, then the refs are corrupt.
    // so return, leaving the previous values in linear.ref
    // to avoid jerking.
    i = ob->refin[j++];
    if (i != floor(i))
        return;

    ob->linear.ref_pos = ob->refin[j++];
}

// wr_ulog.c - wrist robot user logging functions,
// to be modified by InMotion2 programmers
// part of the robot.o robot process
//
// InMotion2 robot system software

// Copyright 2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
// #include "uei_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

void
write_wrist_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;

    ob->log[j++] = ob->wrist.pos.fe;
    ob->log[j++] = ob->wrist.pos.aa;
    ob->log[j++] = ob->wrist.pos.ps;

    ob->log[j++] = ob->wrist.fvel.fe;
    ob->log[j++] = ob->wrist.fvel.aa;
    ob->log[j++] = ob->wrist.fvel.ps;

    ob->log[j++] = ob->wrist.moment_cmd.fe;
    ob->log[j++] = ob->wrist.moment_cmd.aa;
    ob->log[j++] = ob->wrist.moment_cmd.ps;

    ob->log[j++] = rob->grasp.force;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
wrist_write_to_refbuf(void)
{
    u32 i, j;

    if (ob->nwref < 1)
        return;
    if (ob->refwi >= REFARR_ROWS)
        return;                                  // overflow check

    i = ob->refwi;
    j = 0;

    refbuf->refarr[i][j++] = (f64) ob->i;
    refbuf->refarr[i][j++] = ob->wrist.pos.fe;
    refbuf->refarr[i][j++] = ob->wrist.pos.aa;
    refbuf->refarr[i][j++] = ob->wrist.vel.fe;
    refbuf->refarr[i][j++] = ob->wrist.vel.aa;
    ob->refwi++;
}

void
read_wrist_fifo_sample_fn(void)
{
    s32 j;
    f64 i;

    if (ob->nrref < 1)
        return;

    refbuf_to_refin();
    j = 0;

    // if refin[0] is not integral, then the refs are corrupt.
    // so return, leaving the previous values in ankle.ref
    // to avoid jerking.
    i = ob->refin[j++];
    if (i != floor(i))
        return;

    ob->wrist.ref_pos.fe = ob->refin[j++];
    ob->wrist.ref_pos.aa = ob->refin[j++];
}


void
write_wrist_test_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;

    ob->log[j++] = ob->wrist.pos.fe;
    ob->log[j++] = ob->wrist.pos.aa;
    ob->log[j++] = ob->wrist.pos.ps;

    ob->log[j++] = ob->wrist.fvel.fe;
    ob->log[j++] = ob->wrist.fvel.aa;
    ob->log[j++] = ob->wrist.fvel.ps;

    ob->log[j++];
    ob->log[j++];
    ob->log[j++];

    ob->log[j++] = rob->grasp.force;

    ob->log[j++] = ob->wrist.moment_cmd.fe;
    ob->log[j++] = ob->wrist.moment_cmd.aa;
    ob->log[j++] = ob->wrist.moment_cmd.ps;

    ob->log[j++] = rob->wrist.right.torque;
    ob->log[j++] = rob->wrist.left.torque;
    ob->log[j++] = rob->wrist.right.xform * rob->wrist.right.volts;
    ob->log[j++] = rob->wrist.left.xform * rob->wrist.left.volts;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

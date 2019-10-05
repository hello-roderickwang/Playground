// wr_ulog.c - ankle robot user logging functions,
// to be modified by InMotion2 programmers
// part of the robot.o robot process
//
// InMotion2 robot system software

// Copyright 2005-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

void
ankle_write_to_refbuf(void)
{
    u32 i, j;

    if (ob->nwref < 1)
        return;
    if (ob->refwi >= REFARR_ROWS)
        return;                                  // overflow check

    i = ob->refwi;
    j = 0;

    refbuf->refarr[i][j++] = (f64) ob->i;
    refbuf->refarr[i][j++] = ob->ankle.pos.ie;
    refbuf->refarr[i][j++] = ob->ankle.pos.dp;
    refbuf->refarr[i][j++] = ob->ankle.vel.ie;
    refbuf->refarr[i][j++] = ob->ankle.vel.dp;
    ob->refwi++;
}

void
write_ankle_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->ankle.pos.ie;
    ob->log[j++] = ob->ankle.pos.dp;
    ob->log[j++] = ob->ankle.vel.ie;
    ob->log[j++] = ob->ankle.vel.dp;
    ob->log[j++] = ob->ankle.torque.ie;
    ob->log[j++] = ob->ankle.torque.dp;
    ob->log[j++];
    ob->log[j++];
    ob->log[j++] = ob->ankle.moment_cmd.ie;
    ob->log[j++] = ob->ankle.moment_cmd.dp;
    ob->log[j++] = rob->ankle.knee.raw;
    // ob->log[j++] = rob->ankle.knee.angle;
    ob->log[j++] = rob->ankle.right.devtrq;
    ob->log[j++] = rob->ankle.left.devtrq;
    ob->log[j++];
    ob->log[j++];
    ob->log[j++] = rob->ankle.right.volts;
    ob->log[j++] = rob->ankle.left.volts;
    ob->log[j++] = rob->ft.moment.z;

    // rtf_put(ob->dofifo, ob->log, (sizeof(ob->log[0]) * ob->nlog));
    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
write_ankle_accel_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;


    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->ankle.pos.ie;
    ob->log[j++] = ob->ankle.pos.dp;
    ob->log[j++] = ob->ankle.vel.ie;
    ob->log[j++] = ob->ankle.vel.dp;
    ob->log[j++] = ob->ankle.fvel.ie;
    ob->log[j++] = ob->ankle.fvel.dp;
    ob->log[j++] = ob->ankle.vel_mag;
    ob->log[j++] = ob->ankle.accel.ie;
    ob->log[j++] = ob->ankle.accel.dp;
    ob->log[j++] = ob->ankle.accel_mag;

    // rtf_put(ob->dofifo, ob->log, (sizeof(ob->log[0]) * ob->nlog));
    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
read_ankle_fifo_sample_fn(void)
{
    s32 j;
    f64 i;

    if (ob->nrref < 1)
        return;

    // rtf_get(ob->dififo, ob->refin, (sizeof(ob->refin[0]) * ob->nrref));
    // rt_pipe_read(&(ob->dififo), ob->refin, (sizeof(ob->refin[0]) * ob->nrref), P_NORMAL);
    refbuf_to_refin();
    j = 0;

    // if refin[0] is not integral, then the refs are corrupt.
    // so return, leaving the previous values in ankle.ref
    // to avoid jerking.
    i = ob->refin[j++];
    if (i != floor(i))
        return;

    ob->ankle.ref_pos.ie = ob->refin[j++];
    ob->ankle.ref_pos.dp = ob->refin[j++];
}

// added by Konstantinos Michmizos - Winter 2012 (konmic@mit.edu)
void
write_ankle_ped_fifo_fn(void)
{
    s32 j;

    // dpr(3, "write ankle log\n");
    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;  // 1
    ob->log[j++] = ob->ankle.pos.ie;
    ob->log[j++] = ob->ankle.pos.dp; // 3
    ob->log[j++] = ob->ankle.vel.ie;
    ob->log[j++] = ob->ankle.vel.dp;  // 5
    ob->log[j++] = ob->ankle.torque.ie;
    ob->log[j++] = ob->ankle.torque.dp;  // 7
    ob->log[j++] = ob->ankle.moment_cmd.ie;
    ob->log[j++] = ob->ankle.moment_cmd.dp; // 9
    ob->log[j++] = rob->ankle.knee.raw;
    ob->log[j++] = rob->ankle.knee.angle; // 11
    ob->log[j++] = rob->ankle.right.devtrq;
    ob->log[j++] = rob->ankle.left.devtrq; // 13

    // For debugging
    ob->log[j++] = rob->ankle.left.disp;
    ob->log[j++] = rob->ankle.left.volts; // 15
    ob->log[j++] = rob->ankle.right.disp;
    ob->log[j++] = rob->ankle.right.volts; //17
     ob->log[j++] = ob->ankle.Fitts_target_marker; // For Fitts law experiment (marks the onset of a new target)
    ob->log[j++] = ob->ankle.ft_torque.dp; //19
    ob->log[j++] = ob->ankle.ft_torque.ie;
    // rtf_put(ob->dofifo, ob->log, (sizeof(ob->log[0]) * ob->nlog));
    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

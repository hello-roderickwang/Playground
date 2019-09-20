// ulog.c - user logging functions, to be modified by InMotion2 programmers
// part of the robot.o robot process
//
// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
// #include "uei_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

ssize_t log_write(RT_PIPE *, const void *, size_t, int);

// in previous versions of the software, you would change the logging
// function by setting func.write_log to the name of a new function.
// most of the time, you needed to recompile to change functions.
// now I treat the log functions like the slot functions.
// stick their addrs in an array, and let you choose them by index
// using the logfnid variable.
// logfnid defaults to zero, which is the usual write_data_fifo_sample_fn
// function.

void write_data_fifo_sample_fn(void);
void write_motor_test_fifo_sample_fn(void);
void write_grip_test_fifo_sample_fn(void);
void write_adc_fifo_fn(void);
void write_ovadc_fifo_fn(void);
void write_ft_fifo_sample_fn(void);
void write_accel_test_fifo_sample_fn(void);
void write_wrist_fifo_fn(void);
void write_ankle_fifo_fn(void);
void write_vsensor_fifo_sample_fn(void);
void write_enc_fifo_sample_fn(void);
//void write_linear_fifo_fn(void);
void write_wrist_test_fifo_fn(void);
void write_planarwrist_fifo_fn(void);
void write_mfzero_sample_fn(void);
void write_single_motor_fifo_sample_fn(void);
void write_single_motor_vibe_sample_fn(void);
void write_single_motor_vibe_xy_sample_fn(void);
void write_shakeain_sample_fn(void);
void write_jerk_fn(void);
void write_ankle_ped_fifo_fn(void);

void
init_log_fns(void)
{
    ob->log_fns[0] = write_data_fifo_sample_fn;
    ob->log_fns[1] = write_motor_test_fifo_sample_fn;
    ob->log_fns[2] = write_grip_test_fifo_sample_fn;
    ob->log_fns[3] = write_adc_fifo_fn;
    ob->log_fns[4] = write_ovadc_fifo_fn;
    ob->log_fns[5];
    ob->log_fns[6] = write_ft_fifo_sample_fn;
    ob->log_fns[7] = write_accel_test_fifo_sample_fn;
    ob->log_fns[8] = write_wrist_fifo_fn;
    ob->log_fns[9] = write_ankle_fifo_fn;
    ob->log_fns[10] = write_vsensor_fifo_sample_fn;
    ob->log_fns[11] = write_enc_fifo_sample_fn;
    //    ob->log_fns[12] = write_linear_fifo_fn;
    ob->log_fns[13] = write_wrist_test_fifo_fn;
    ob->log_fns[14] = write_planarwrist_fifo_fn;
    ob->log_fns[15] = write_mfzero_sample_fn;
    ob->log_fns[16] = write_single_motor_fifo_sample_fn;
    ob->log_fns[17] = write_single_motor_vibe_sample_fn;
    ob->log_fns[18] = write_single_motor_vibe_xy_sample_fn;
    ob->log_fns[19] = write_shakeain_sample_fn;
    ob->log_fns[20] = write_jerk_fn;
    ob->log_fns[21] = write_ankle_ped_fifo_fn;
}

// handle ref fns similarly to log fns

void read_ankle_fifo_sample_fn(void);
void read_planar_fifo_sample_fn(void);
void read_wrist_fifo_sample_fn(void);

void
init_ref_fns(void)
{
    // ob->ref_fns[0] = read_data_fifo_sample_fn;
    ob->ref_fns[1] = read_ankle_fifo_sample_fn;
    ob->ref_fns[2] = read_planar_fifo_sample_fn;
    ob->ref_fns[3] = read_wrist_fifo_sample_fn;
}

// ascii logger
ssize_t
log_write(RT_PIPE *pipe, const void *buf, size_t size, int mode)
{
    if (! ob->asciilog)
	return rt_pipe_write(pipe, buf, size, mode);

    int i;
    int end = 0;
    char line[4096];
    const f64 *buf64 = (const f64 *) buf;

    for (i = 0; i < size / sizeof(buf64[0]); i++)
	end += sprintf(&line[end], "%.6f ", buf64[i]);

    line[end - 1] = '\n';

    return rt_pipe_write(&(ob->dofifo), line, end, mode);
}

void
planar_write_to_refbuf(void)
{
    u32 i, j;

    if (ob->nwref < 1)
        return;
    if (ob->refwi >= REFARR_ROWS)
        return;                                  // overflow check

    i = ob->refwi;
    j = 0;

    refbuf->refarr[i][j++] = (f64) ob->i;
    refbuf->refarr[i][j++] = ob->pos.x;
    refbuf->refarr[i][j++] = ob->pos.y;
    refbuf->refarr[i][j++] = ob->vel.x;
    refbuf->refarr[i][j++] = ob->vel.y;
    ob->refwi++;
}

// write counter, then nlog doubles from log array, into dofifo.
// this is the normal default logger

void
write_data_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->pos.x;
    ob->log[j++] = ob->pos.y;

    ob->log[j++] = ob->vel.x;
    ob->log[j++] = ob->vel.y;

    ob->log[j++] = rob->ft.world.x;
    ob->log[j++] = rob->ft.world.y;
    ob->log[j++] = rob->ft.world.z;
    // ob->log[j++] = rob->grasp.force;
    // replaced this column with targetnumber
    ob->log[j++] = ob->targetnumber;

    ob->log[j++] = ob->hand.pos;
    ob->log[j++] = ob->hand.vel;
    ob->log[j++] = rob->hand.motor.devfrc;
    ob->log[j++] = ob->hand.force;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

// write counter, then nlog doubles from log array, into dofifo.
// for motor_tests program

void
write_motor_test_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = rob->ft.moment.z;
    ob->log[j++] = rob->shoulder.angle.rad;
    ob->log[j++] = rob->elbow.angle.rad;
    ob->log[j++] = ob->raw_torque_volts.s;
    ob->log[j++] = ob->raw_torque_volts.e;
    ob->log[j++] = rob->wrist.right.disp;
    ob->log[j++] = rob->wrist.left.disp;
    ob->log[j++] = rob->wrist.ps.disp;
    //    ob->log[j++] = rob->linear.motor.disp;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// test grip sensor

void
write_grip_test_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = rob->grasp.raw;
    ob->log[j++] = rob->ft.xymag;
    ob->log[j++] = rob->grasp.force;
    ob->log[j++] = rob->ft.dev.x;
    ob->log[j++] = rob->ft.dev.y;
    ob->log[j++] = rob->ft.dev.z;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// test avg ft

void
write_adc_fifo_fn(void)
{
    u32 i, j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    for (i = 0; i < 16; i++) {
        ob->log[j++] = daq->adcvolts[i];
    }


    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// test oversampled adc

void
write_ovadc_fifo_fn(void)
{
    u32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = daq->adcvolts[0];
    ob->log[j++] = daq->adcvoltsmean[0];
    ob->log[j++] = daq->adcvoltsmed[0];

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// test ft

void
write_ft_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = rob->ft.dev.x;
    ob->log[j++] = rob->ft.dev.y;
    ob->log[j++] = rob->ft.dev.z;
    ob->log[j++] = rob->ft.moment.x;
    ob->log[j++] = rob->ft.moment.y;
    ob->log[j++] = rob->ft.moment.z;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}


//
// test ft

void
write_ft_vel_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->pos.x;
    ob->log[j++] = ob->pos.y;
    ob->log[j++] = daq->adcvolts[6];
    ob->log[j++] = daq->adcvolts[7];
    ob->log[j++] = (f64) daq->dienc[1];
    ob->log[j++] = (f64) daq->dienc[0];

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// test ft

void
old_write_ft_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = rob->ft.dev.x;
    ob->log[j++] = rob->ft.dev.y;
    ob->log[j++] = rob->ft.dev.z;
    ob->log[j++] = rob->ft.raw[0];
    ob->log[j++] = rob->ft.raw[1];
    ob->log[j++] = rob->ft.raw[2];

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
write_ft_vs_motor_test_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->pos.x;
    ob->log[j++] = ob->pos.y;
    ob->log[j++] = ob->motor_force.x;
    ob->log[j++] = ob->motor_force.y;
    ob->log[j++] = rob->ft.world.x;
    ob->log[j++] = rob->ft.world.y;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}


//
// test accel sensor

void
write_accel_test_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = rob->accel.curr[0];
    ob->log[j++] = rob->accel.curr[1];
    ob->log[j++] = rob->accel.curr[2];
    ob->log[j++] = rob->ft.dev.x;
    ob->log[j++] = rob->ft.dev.y;
    ob->log[j++] = rob->ft.dev.z;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

// write counter, then nlog doubles from log array, into dofifo.

void
write_wrist_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->pos.x;
    ob->log[j++] = ob->pos.y;
    ob->log[j++] = daq->adcvolts[8];
    ob->log[j++] = daq->adcvolts[9];
    ob->log[j++];
    ob->log[j++];
    ob->log[j++];

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
write_vsensor_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    // ft force
    ob->log[j++] = rob->ft.world.x;
    ob->log[j++] = rob->ft.world.y;
    // current sensor
    ob->log[j++] = daq->adcvolts[8];
    ob->log[j++] = daq->adcvolts[9];
    ob->log[j++] = daq->adcvolts[10];
    ob->log[j++] = daq->adcvolts[11];

    ob->log[j++] = ob->motor_torque.s;
    ob->log[j++] = ob->motor_torque.e;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
write_enc_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;

    // elbow 0 shoulder 1
    ob->log[j++] = daq->dienc[0];
    ob->log[j++] = daq->dienc[1];
    ob->log[j++] = daq->dienc_vel[0];
    ob->log[j++] = daq->dienc_vel[1];
    ob->log[j++] = daq->dienc_accel[0];
    ob->log[j++] = daq->dienc_accel[1];

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

// doesn't really do i/o, just some calcs
void
write_mfzero_sample_fn(void)
{
    s32 i;

    if (ob->nlog < 1)
        return;

    for (i = 0; i < 8; i++) {
        ob->aodiff[i] = fabs(daq->adcvolts[i + 8]);
        // prime the pump to ignore artifacts when we change freqs
        ob->aocum[i] += (ob->aodiff[i] * ob->aodiff[i]);
        ob->aorms[i] = sqrt(ob->aocum[i] / ob->aocount);
        ob->aocum1[i] += ob->aodiff[i];
        ob->aoavg[i] = ob->aocum1[i] / ob->aocount;
    }
    ob->aocount++;
}

void
read_planar_fifo_sample_fn(void)
{
    s32 j;
    f64 i;
    s32 ret;

    if (ob->nrref < 1)
        return;
    ret =
        rt_pipe_read(&(ob->dififo), ob->refin, (sizeof(ob->refin[0]) * ob->nrref),
                     TM_NONBLOCK);
    j = 0;

    // if refin[0] is not integral, then the refs are corrupt.
    // so return, leaving the previous values in ankle.ref
    // to avoid jerking.
    i = ob->refin[j++];
    if (i != floor(i))
        return;

    ob->ref.pos.x = ob->refin[j++];
    ob->ref.pos.y = ob->refin[j++];
}

void
write_planarwrist_fifo_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;

    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->pos.x;
    ob->log[j++] = ob->pos.y;

    ob->log[j++] = ob->vel.x;
    ob->log[j++] = ob->vel.y;

    ob->log[j++] = rob->ft.world.x;
    ob->log[j++] = rob->ft.world.y;
    ob->log[j++] = rob->ft.world.z;
    ob->log[j++] = rob->grasp.force;

    ob->log[j++] = ob->wrist.pos.fe;
    ob->log[j++] = ob->wrist.pos.aa;
    ob->log[j++] = ob->wrist.pos.ps;

    ob->log[j++] = ob->wrist.fvel.fe;
    ob->log[j++] = ob->wrist.fvel.aa;
    ob->log[j++] = ob->wrist.fvel.ps;

    ob->log[j++];
    ob->log[j++];
    ob->log[j++];

    ob->log[j++] = 0.0;                          // pitch potentiometer, placeholder
    ob->log[j++] = 0.0;                          // yaw potentiometer, placeholder

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

//
// logger for single motor spring test
//

void
write_single_motor_fifo_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->spring.disp.s;
    ob->log[j++] = ob->spring.disp.e;
    ob->log[j++] = ob->raw_torque_volts.s;
    ob->log[j++] = ob->raw_torque_volts.e;
    ob->log[j++] = ob->spring.stiff.s;
    ob->log[j++] = ob->spring.stiff.e;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}


//
// logger for spring test2
//

void
write_single_motor_vibe_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->spring.disp.s;
    ob->log[j++] = ob->spring.disp.e;
    ob->log[j++] = ob->tsvibe;
    ob->log[j++] = ob->tevibe;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

void
write_single_motor_vibe_xy_sample_fn(void)
{
    s32 j;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = ob->spring.dispxy.x;
    ob->log[j++] = ob->spring.dispxy.y;
    ob->log[j++] = ob->txvibe;
    ob->log[j++] = ob->tyvibe;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

// doesn't really do i/o, just some calcs
void
write_shakeain_sample_fn(void)
{
    s32 i;

    if (ob->nlog < 1)
        return;

    ob->aocount++;                               // start at 1
    for (i = 0; i < 8; i++) {
        ob->aodiff[i] = daq->adcvolts[i + 8];
        // prime the pump to ignore artifacts when we change freqs
        ob->aocum[i] += (ob->aodiff[i] * ob->aodiff[i]);
        ob->aorms[i] = sqrt(ob->aocum[i] / ob->aocount);
        ob->aocum1[i] += ob->aodiff[i];
        ob->aoavg[i] = ob->aocum1[i] / ob->aocount;
    }
}

void
write_jerk_fn(void)
{
    s32 j;
    f64 l, r, x, w, w2;

    if (ob->nlog < 1)
        return;

    j = 0;
    ob->log[j++] = (f64) ob->i;
    ob->log[j++] = (f64) ob->slot[00].i;
    ob->log[j++] = x = ob->slot[0].bcur.point.x;
    ob->log[j++] = w = ob->slot[0].bcur.w;

    w2 = w / 2.0;
    l = x - w2;
    r = x + w2;
    ob->log[j++] = l;
    ob->log[j++] = r;
    ob->log[j++] = x = ob->slot[0].bcur.point.x;

    log_write(&(ob->dofifo), ob->log, (sizeof(ob->log[0]) * ob->nlog), P_NORMAL);
}

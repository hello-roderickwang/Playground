// an_sensact.c - ankle robot sensors and actuators
// part of the robot.o robot process

// convert from raw data taken from sensor inputs to useful formats
// convert from from useful formats to raw data to be sent to actuators

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
ankle_init(void)
{
    // Rob structure
    rob->ankle.left.enc_channel = 1;
    rob->ankle.left.disp = 2.0;
    rob->ankle.left.devtrq = 2.0;
    rob->ankle.left.xform = 0.0116;
    rob->ankle.left.volts = 2.0;
    rob->ankle.left.ao_channel = 1;

    rob->ankle.right.enc_channel = 0;
    rob->ankle.right.disp = 2.0;
    rob->ankle.right.devtrq = 2.0;
    rob->ankle.right.xform = 0.0116;
    rob->ankle.right.volts = 2.0;
    rob->ankle.right.ao_channel = 0;

    rob->ankle.trans.ratio = 7.0;

    // Ob structure
    ob->ankle.pos.ie = 0.0;
    ob->ankle.vel.ie = 0.0;
    ob->ankle.fvel.ie = 0.0;
    ob->ankle.torque.ie = 0.0;

    ob->ankle.pos.dp = 0.0;
    ob->ankle.vel.dp = 0.0;
    ob->ankle.fvel.dp = 0.0;
    ob->ankle.torque.dp = 0.0;

    // Prev structure
    prev->ankle.pos.ie = 0.0;
    prev->ankle.vel.ie = 0.0;
    prev->ankle.fvel.ie = 0.0;

    prev->ankle.pos.dp = 0.0;
    prev->ankle.vel.dp = 0.0;
    prev->ankle.fvel.dp = 0.0;
}

// make sure denominators are non-zero
static void
check_ankle_denominators(void)
{
    if (fabs(rob->ankle.trans.ratio) < .00001)
        rob->ankle.trans.ratio = 35.0;
    if (fabs(rob->ankle.trans.ball_ball_width) < .00001)
        rob->ankle.trans.ball_ball_width = 0.2;
    if (fabs(rob->ankle.left.xform) < .00001)
        rob->ankle.left.xform = .02;
    if (fabs(rob->ankle.right.xform) < .00001)
        rob->ankle.right.xform = .02;
    if (fabs(rob->ankle.trans.ankle_ball_length) < .00001)
        rob->ankle.trans.ankle_ball_length = .15;
    if (fabs(rob->ankle.trans.av_shin_length) < .00001)
        rob->ankle.trans.av_shin_length = .40;
    if (fabs(rob->ankle.trans.lead) < .00001)
        rob->ankle.trans.lead = 0.025;
}

//
// link data from encoder via motor to world coordinates
// pc7266 and pci4e are both counter cards, should have one or tother.
void
ankle_sensor(void)
{
    f64 av_link_disp;
    f64 asin_tmp;

    if (!ob->have_ankle)
	return;
    if (!(rob->pci4e.have || ob->have_can))
	return;

    check_ankle_denominators();

    // traction drive linear encoders
    if (rob->pci4e.have) {
	rob->ankle.left.disp = -rob->pci4e.lenc[rob->ankle.left.enc_channel];
	rob->ankle.right.disp = -rob->pci4e.lenc[rob->ankle.right.enc_channel];
    } else if (ob->have_can) {
	rob->ankle.left.disp = rob->can.pos_raw[rob->ankle.left.enc_channel];
	rob->ankle.right.disp = rob->can.pos_raw[rob->ankle.right.enc_channel];
	rob->ankle.left.disp = rob->ankle.left.disp * rob->pci4e.scale;
	rob->ankle.right.disp = rob->ankle.right.disp * rob->pci4e.scale;
    }
    // motor rotary encoders
    if (rob->pci4e.have) {
	rob->ankle.left.rot_disp = -rob->pci4e.lenc[rob->ankle.left.rot_enc_channel];
	rob->ankle.right.rot_disp = -rob->pci4e.lenc[rob->ankle.right.rot_enc_channel];
    } else if (ob->have_can) {
	rob->ankle.left.rot_disp = -rob->can.pos_raw[rob->ankle.left.rot_enc_channel];
	rob->ankle.right.rot_disp = -rob->can.pos_raw[rob->ankle.right.rot_enc_channel];
	rob->ankle.left.rot_disp = rob->ankle.left.rot_disp * rob->pci4e.scale;
	rob->ankle.right.rot_disp = rob->ankle.right.rot_disp * rob->pci4e.scale;
}
    // these disps are the same units as the right.disp and left.disp
    rob->ankle.right.rot_lin_disp = rob->ankle.right.rot_disp *
	rob->ankle.trans.enc_xform * rob->ankle.trans.lead;
    rob->ankle.left.rot_lin_disp = rob->ankle.left.rot_disp *
	rob->ankle.trans.enc_xform * rob->ankle.trans.lead;


    // device space velocities for linear and rot
    rob->ankle.left.vel = (rob->ankle.left.disp - prev->ankle.disp.l) * ob->Hz;
    rob->ankle.right.vel = (rob->ankle.right.disp - prev->ankle.disp.r) * ob->Hz;
    rob->ankle.left.rot_lin_vel =
	(rob->ankle.left.rot_lin_disp - prev->ankle.rot_lin_disp.l) * ob->Hz;
    rob->ankle.right.rot_lin_vel =
	(rob->ankle.right.rot_lin_disp - prev->ankle.rot_lin_disp.r) * ob->Hz;

    // world space position
    ob->ankle.pos.ie = atan(((rob->ankle.right.disp - rob->ankle.left.disp)
		/ 2.) / (rob->ankle.trans.ball_ball_width / 2.)) +
	ob->ankle.offset.ie;

    av_link_disp = (rob->ankle.trans.av_actuator_length - rob->ankle.right.disp
	    + rob->ankle.trans.av_actuator_length - rob->ankle.left.disp) / 2.;

    asin_tmp = (((rob->ankle.trans.ankle_ball_length * rob->ankle.trans.ankle_ball_length)
		+ (rob->ankle.trans.av_shin_length * rob->ankle.trans.av_shin_length)
		- (av_link_disp * av_link_disp))
	    / (2. * rob->ankle.trans.ankle_ball_length
		* rob->ankle.trans.av_shin_length));

    if (fabs(asin_tmp) > 1.0)
	asin_tmp = 0.0;
    ob->ankle.pos.dp = xasin(asin_tmp) + ob->ankle.offset.dp;

    // knee pot
//    rob->ankle.knee.raw = daq->adcvolts[rob->ankle.knee.channel];
    // 7000 = 5V, 7000 / 5 = 1400
    rob->ankle.knee.raw = dbracket(rob->ankle.knee.bias + rob->can.analog1[rob->ankle.knee.channel] * rob->ankle.knee.gain, -10.0, 10.0);
/*    rob->ankle.knee.angle = (rob->ankle.knee.raw * rob->ankle.knee.raw)
	* rob->ankle.knee.xform1
	+ rob->ankle.knee.raw * rob->ankle.knee.xform2 + rob->ankle.knee.bias;
*/
}

// calculate velocity and filtered velocity
void
ankle_calc_vel(void)
{
    if (!ob->have_ankle)
        return;

    ob->ankle.vel.ie = (ob->ankle.pos.ie - prev->ankle.pos.ie) * ob->Hz;
    ob->ankle.vel.dp = (ob->ankle.pos.dp - prev->ankle.pos.dp) * ob->Hz;

    ob->ankle.fvel.ie = butter(ob->ankle.vel.ie, prev->ankle.vel.ie, prev->ankle.fvel.ie);
    ob->ankle.fvel.dp = butter(ob->ankle.vel.dp, prev->ankle.vel.dp, prev->ankle.fvel.dp);

    ob->ankle.vel_mag = hypot(ob->ankle.vel.ie, ob->ankle.vel.dp);

    ob->ankle.accel.ie = (ob->ankle.vel.ie - prev->ankle.vel.ie) * ob->Hz;
    ob->ankle.accel.dp = (ob->ankle.vel.dp - prev->ankle.vel.dp) * ob->Hz;
    ob->ankle.accel_mag = hypot(ob->ankle.accel.ie, ob->ankle.accel.dp);
}

void
ankle_moment(void)
{
    f64 right_torque, left_torque;
    check_ankle_denominators();

    // from command torques
    ob->ankle.moment_cmd.dp = -(rob->ankle.left.devtrq + rob->ankle.right.devtrq)
        * 2 * M_PI * rob->ankle.trans.ankle_ball_length / rob->ankle.trans.lead;
    ob->ankle.moment_cmd.ie = (rob->ankle.left.devtrq - rob->ankle.right.devtrq)
        * M_PI * rob->ankle.trans.ball_ball_width / rob->ankle.trans.lead;
}

//
// convert from the torque output of the controller (in world coordinates)
//      to voltage input to the actuators (in motor coordinates)
void
dac_ankle_actuator(void)
{
    rl volts;
    rl devtrq;
    se pfov;

    if (!ob->have_ankle)
        return;

    check_ankle_denominators();

    // device torques
    devtrq.l = (-ob->ankle.torque.dp + ob->ankle.torque.ie)
        / (2.0 * rob->ankle.trans.ratio);
    devtrq.r = (-ob->ankle.torque.dp - ob->ankle.torque.ie)
        / (2.0 * rob->ankle.trans.ratio);

    devtrq.l = (-ob->ankle.torque.dp / rob->ankle.trans.ankle_ball_length
                + ob->ankle.torque.ie / (rob->ankle.trans.ball_ball_width / 2))
        * (rob->ankle.trans.lead / (4. * M_PI));
    devtrq.r = (-ob->ankle.torque.dp / rob->ankle.trans.ankle_ball_length
                - ob->ankle.torque.ie / (rob->ankle.trans.ball_ball_width / 2))
        * (rob->ankle.trans.lead / (4. * M_PI));

    // vibrate
    if (ob->vibrate) {
        devtrq.l += (ob->xvibe / 100.);
        devtrq.r += (ob->yvibe / 100.);
    }
    // command voltages
    volts.l = devtrq.l / rob->ankle.left.xform;
    volts.r = devtrq.r / rob->ankle.right.xform;

    rob->ankle.left.devtrq = devtrq.l;
    rob->ankle.right.devtrq = devtrq.r;

    // raw voltages?
    if (ob->test_raw_torque) {
        volts.l = rob->ankle.left.test_volts;
        volts.r = rob->ankle.right.test_volts;
    }
    // preserve force orientation
    pfov.s = volts.l;
    pfov.e = volts.r;
    pfov = preserve_orientation(pfov, ob->ankle.rl_pfomax);
    pfov = preserve_orientation(pfov, ob->ankle.rl_pfotest);
    rob->ankle.left.volts = pfov.s;
    rob->ankle.right.volts = pfov.e;

    // apply pfo values to devtrqs, so logs are correct
    rob->ankle.left.devtrq = rob->ankle.left.volts * rob->ankle.left.xform;
    rob->ankle.right.devtrq = rob->ankle.right.volts * rob->ankle.right.xform;

    // write daqs
    if (ob->ankle.ueimf) {
	uei_aout_write(rob->ankle.left.volts, rob->ankle.right.volts);
    } else if (ob->have_can) {
        s32 l, r;

        l = rob->ankle.left.volts * 100.;
        r = rob->ankle.right.volts * 100.;

        can_mot_write(rob->ankle.left.ao_channel, l);
        can_mot_write(rob->ankle.right.ao_channel, r);
    } else {
	uei_aout32_write(rob->ankle.uei_ao_board_handle,
		rob->ankle.left.ao_channel, rob->ankle.left.volts);
	uei_aout32_write(rob->ankle.uei_ao_board_handle,
		rob->ankle.right.ao_channel, rob->ankle.right.volts);
    }
}

void
ankle_after_compute_controls(void)
{
    // add ankle parameters (do whole structure at once)
    prev->ankle.pos = ob->ankle.pos;
    prev->ankle.vel = ob->ankle.vel;
    prev->ankle.fvel = ob->ankle.fvel;
    prev->ankle.disp.l = rob->ankle.left.disp;
    prev->ankle.disp.r = rob->ankle.right.disp;
    prev->ankle.rot_lin_disp.l = rob->ankle.left.rot_lin_disp;
    prev->ankle.rot_lin_disp.r = rob->ankle.right.rot_lin_disp;
}

void
ankle_set_zero_torque(void)
{
    // include ankle motor parameters
    ob->ankle.torque.dp = 0.0;
    ob->ankle.torque.ie = 0.0;
    rob->ankle.left.devtrq = 0.0;
    rob->ankle.right.devtrq = 0.0;
    rob->ankle.left.volts = 0.0;
    rob->ankle.right.volts = 0.0;
}

void
ankle_write_zero_torque(void)
{
    // include ankle motor parameters
    ankle_set_zero_torque();
    if (ob->ankle.ueimf) {
	uei_aout_write(rob->ankle.left.volts, rob->ankle.right.volts);
    } else if (ob->have_can) {
	can_mot_write(rob->ankle.left.ao_channel, 0);
	can_mot_write(rob->ankle.right.ao_channel, 0);
    } else {
	uei_aout32_write(rob->ankle.uei_ao_board_handle,
		rob->ankle.left.ao_channel, rob->ankle.left.volts);
	uei_aout32_write(rob->ankle.uei_ao_board_handle,
		rob->ankle.right.ao_channel, rob->ankle.right.volts);
    }
}

// if we get one of these errors, return from the function immediately.
// a stops error may cause a slip, but we don't want to detect those.

void
ankle_check_safety(void)
{
    if (!ob->have_ankle)
        return;
    // give it time to start
    if (ob->i < 100)
        return;
    if (ob->safety.override)
        return;

    // did we hit the stops
    if (ob->ankle.accel_mag > ob->ankle.safety_accel
        || ob->ankle.vel_mag > ob->ankle.safety_vel) {
        ob->fault = 1;
        ob->paused = 1;
        do_error(ERR_AN_HIT_STOPS);
        return;
    }
    // did the linear position slip wrt the rotary position
    if (fabs(rob->ankle.left.vel - rob->ankle.left.rot_lin_vel)
        > rob->ankle.trans.slip_thresh) {
        ob->fault = 1;
        ob->paused = 1;
        do_error(ERR_AN_SHAFT_SLIP_LEFT);
        return;
    }
    if (fabs(rob->ankle.right.vel - rob->ankle.right.rot_lin_vel)
        > rob->ankle.trans.slip_thresh) {
        ob->fault = 1;
        ob->paused = 1;
        do_error(ERR_AN_SHAFT_SLIP_RIGHT);
        return;
    }
}

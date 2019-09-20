// wr_sensact.c - wrist robot sensors and actuators
// part of the robot.o robot process

// convert from raw data taken from sensor inputs to useful formats
// convert from from useful formats to raw data to be sent to actuators

// InMotion2 robot system software

// Copyright 2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"


void
wrist_init(void)
{
    // Rob structure
    rob->wrist.left.enc_channel = 1;
    rob->wrist.left.disp = 2.0;
    rob->wrist.left.vel = 0.0;
    rob->wrist.left.devtrq = 2.0;
    rob->wrist.left.xform = 0.0116;
    rob->wrist.left.enc_xform = 0.000153398078789;
    rob->wrist.left.volts = 2.0;
    rob->wrist.left.ao_channel = 1;

    rob->wrist.right.enc_channel = 0;
    rob->wrist.right.disp = 2.0;
    rob->wrist.right.vel = 0.0;
    rob->wrist.right.devtrq = 2.0;
    rob->wrist.right.enc_xform = 0.000153398078789;
    rob->wrist.right.volts = 2.0;
    rob->wrist.right.ao_channel = 0;

    rob->wrist.ps.enc_channel = 2;
    rob->wrist.ps.disp = 2.0;
    rob->wrist.ps.vel = 0.0;
    rob->wrist.ps.devtrq = 2.0;
    rob->wrist.ps.enc_xform = 0.000153398078789;
    rob->wrist.ps.volts = 2.0;
    rob->wrist.ps.ao_channel = 2;

    rob->wrist.gears.diff = 7;
    rob->wrist.gears.ps = 10.5;
    rob->wrist.uei_ao_board_handle = 1;

    // Ob structure
    ob->wrist.pos.fe = 0.0;
    ob->wrist.pos.aa = 0.0;
    ob->wrist.pos.ps = 0.0;
    ob->wrist.vel.fe = 0.0;
    ob->wrist.vel.aa = 0.0;
    ob->wrist.vel.ps = 0.0;
    ob->wrist.fvel.fe = 0.0;
    ob->wrist.fvel.aa = 0.0;
    ob->wrist.fvel.ps = 0.0;
    ob->wrist.torque.fe = 0.0;
    ob->wrist.torque.aa = 0.0;
    ob->wrist.torque.ps = 0.0;

    // Prev structure
    prev->wrist.pos.fe = 0.0;
    prev->wrist.pos.aa = 0.0;
    prev->wrist.pos.ps = 0.0;
    prev->wrist.right.vel = 0.0;
    prev->wrist.left.vel = 0.0;
    prev->wrist.ps.vel = 0.0;
    prev->wrist.right.fvel = 0.0;
    prev->wrist.left.fvel = 0.0;
    prev->wrist.ps.vel = 0.0;
    prev->wrist.vel.fe = 0.0;
    prev->wrist.vel.aa = 0.0;
    prev->wrist.vel.ps = 0.0;
    prev->wrist.fvel.fe = 0.0;
    prev->wrist.fvel.aa = 0.0;
    prev->wrist.fvel.ps = 0.0;
}

// link data from encoder via motor to world coordinates
void
wrist_sensor(void)
{
    if (!ob->have_wrist) return;

    if (rob->pci4e.have) {
	rob->wrist.left.disp =
	    rob->pci4e.enc[rob->wrist.left.enc_channel];
	rob->wrist.right.disp =
	    rob->pci4e.enc[rob->wrist.right.enc_channel];
	rob->wrist.ps.disp = rob->pci4e.enc[rob->wrist.ps.enc_channel];
    } else if (ob->have_can) {
	rob->wrist.left.disp =
	    rob->can.pos_raw[rob->wrist.left.enc_channel]
            * rob->wrist.left.enc_xform;
	rob->wrist.right.disp =
	    rob->can.pos_raw[rob->wrist.right.enc_channel]
            * rob->wrist.right.enc_xform;
	rob->wrist.ps.disp =
            rob->can.pos_raw[rob->wrist.ps.enc_channel]
            * rob->wrist.ps.enc_xform;
    }

    if (ob->sim.sensors) {
      ob->wrist.pos.fe = ob->sim.wr_pos.fe;
      ob->wrist.pos.aa = ob->sim.wr_pos.aa;
      ob->wrist.pos.ps = ob->sim.wr_pos.ps;
    }
    else {
        if (fabs(rob->wrist.gears.diff) < .0001) rob->wrist.gears.diff = 1.0;
        ob->wrist.pos.fe = (rob->wrist.left.disp +
             rob->wrist.right.disp) / (2.0 * rob->wrist.gears.diff) +
             ob->wrist.offset.fe;
        ob->wrist.pos.aa = (rob->wrist.left.disp -
             rob->wrist.right.disp) / (2.0 * rob->wrist.gears.diff) +
             ob->wrist.offset.aa;
        if (fabs(rob->wrist.gears.ps) < .0001) rob->wrist.gears.ps = 1.0;
        ob->wrist.pos.ps = rob->wrist.ps.disp / rob->wrist.gears.ps +
             ob->wrist.offset.ps;
    }
}

// calculate velocity and filtered velocity
void
wrist_calc_vel(void)
{
    if (!ob->have_wrist)
        return;

    if (ob->sim.sensors) {
        ob->wrist.vel.fe = ob->sim.wr_vel.fe;
        ob->wrist.vel.aa = ob->sim.wr_vel.aa;
        ob->wrist.vel.ps = ob->sim.wr_vel.ps;
    }
    else {
        ob->wrist.vel.fe =
	    (ob->wrist.pos.fe - prev->wrist.pos.fe) * ob->Hz;
        ob->wrist.vel.aa =
	    (ob->wrist.pos.aa - prev->wrist.pos.aa) * ob->Hz;
        ob->wrist.vel.ps =
	    (ob->wrist.pos.ps - prev->wrist.pos.ps) * ob->Hz;
    }

    // TODO: must normalize for 0 to 2 pi transition!
    rob->wrist.left.vel =
	(rob->wrist.left.disp - prev->wrist.left.disp) * ob->Hz;
    rob->wrist.right.vel =
	(rob->wrist.right.disp - prev->wrist.right.disp) * ob->Hz;
    rob->wrist.ps.vel =
	(rob->wrist.ps.disp - prev->wrist.ps.disp) * ob->Hz;

    ob->wrist.fvel.fe =
	butter(ob->wrist.vel.fe, prev->wrist.vel.fe,
	       prev->wrist.fvel.fe);
    ob->wrist.fvel.aa =
	butter(ob->wrist.vel.aa, prev->wrist.vel.aa,
	       prev->wrist.fvel.aa);
    ob->wrist.fvel.ps =
	butter(ob->wrist.vel.ps, prev->wrist.vel.ps,
	       prev->wrist.fvel.ps);

    rob->wrist.left.fvel =
	butter(rob->wrist.left.vel, prev->wrist.left.vel,
	       prev->wrist.left.fvel);
    rob->wrist.right.fvel =
	butter(rob->wrist.right.vel, prev->wrist.right.vel,
	       prev->wrist.right.fvel);
    rob->wrist.ps.fvel =
	butter(rob->wrist.ps.vel, prev->wrist.ps.vel,
	       prev->wrist.ps.fvel);
    ob->wrist.velmag = hypot(ob->wrist.fvel.fe, ob->wrist.fvel.aa);

    ob->wrist.accel.fe =
	(ob->wrist.fvel.fe - prev->wrist.fvel.fe) * ob->Hz;
    ob->wrist.accel.aa =
	(ob->wrist.fvel.aa - prev->wrist.fvel.aa) * ob->Hz;
    ob->wrist.accel.ps =
	(ob->wrist.fvel.ps - prev->wrist.fvel.ps) * ob->Hz;
    ob->wrist.accelmag = hypot(ob->wrist.accel.fe, ob->wrist.accel.aa);

    ob->wrist.jerk.fe =
	(ob->wrist.accel.fe - prev->wrist.accel.fe) * ob->Hz;
    ob->wrist.jerk.aa =
	(ob->wrist.accel.aa - prev->wrist.accel.aa) * ob->Hz;
    ob->wrist.jerk.ps =
	(ob->wrist.accel.ps - prev->wrist.accel.ps) * ob->Hz;
    ob->wrist.jerkmag = hypot(ob->wrist.jerk.fe, ob->wrist.jerk.aa);
}

void
wrist_moment(void)
{
    // from command torques
    ob->wrist.moment_cmd.fe = -ob->wrist.torque.fe;
    ob->wrist.moment_cmd.aa = -ob->wrist.torque.aa;
    ob->wrist.moment_cmd.ps = -ob->wrist.torque.ps;
}

//
// convert from the torque output of the controller (in world coordinates)
//      to voltage input to the actuators (in motor coordinates)
void
dac_wrist_actuator(void)
{
    rlps oldvolts, volts;
    rlps devtrq;
    se pfov;
    f64 pspfov;
    rlps volts_ratio;

    if (!ob->have_wrist) return;

    // I changed the sign of devtrq.r (not sure why this change needed?)
    // -dustin
    // device torques
    if (fabs(rob->wrist.gears.diff) < .0001) rob->wrist.gears.diff = 1.0;
    devtrq.l = -(ob->wrist.torque.aa +
	    ob->wrist.torque.fe) / (2.0 * rob->wrist.gears.diff);
    devtrq.r = -(ob->wrist.torque.aa -
	    ob->wrist.torque.fe) / (2.0 * rob->wrist.gears.diff);
    if (fabs(rob->wrist.gears.ps) < .0001) rob->wrist.gears.ps = 1.0;
    devtrq.ps = ob->wrist.torque.ps / rob->wrist.gears.ps;

    // gravity compensation, note that this happens even
    // without a controller if not paused
    if (fabs(ob->wrist.ps_gcomp) > 1.0)
	ob->wrist.ps_gcomp = 0.0;
    devtrq.ps += ob->wrist.ps_gcomp * sin(ob->wrist.pos.ps);

    // make sure these signs are right
    // Bad = 15 degrees
#define Bad (M_PI / 12.0)
    if (fabs(ob->wrist.diff_gcomp) > 1.0)
	ob->wrist.diff_gcomp = 0.0;
    // gcomp is Mt * mgl / 2.0
    devtrq.l += ob->wrist.diff_gcomp * cos(ob->wrist.pos.aa + Bad) *
	(sin(ob->wrist.pos.ps) - cos(ob->wrist.pos.ps));
    devtrq.r += -ob->wrist.diff_gcomp * cos(ob->wrist.pos.aa + Bad) *
	(sin(ob->wrist.pos.ps) + cos(ob->wrist.pos.ps));

    // vibrate
    if (ob->vibrate) {
	devtrq.l += (ob->xvibe / 100.);
	devtrq.r += (ob->yvibe / 100.);
	devtrq.ps += (ob->yvibe / 100.);
    }

    // torques to command voltages
    if (fabs(rob->wrist.left.xform) < .0001) rob->wrist.left.xform = 1.0;
    volts.l = devtrq.l / rob->wrist.left.xform + rob->wrist.left.bias;
    if (fabs(rob->wrist.right.xform) < .0001) rob->wrist.right.xform = 1.0;
    volts.r = devtrq.r / rob->wrist.right.xform + rob->wrist.right.bias;
    if (fabs(rob->wrist.ps.xform) < .0001) rob->wrist.ps.xform = 1.0;
    volts.ps = devtrq.ps / rob->wrist.ps.xform + rob->wrist.ps.bias;

    rob->wrist.left.devtrq = devtrq.l;
    rob->wrist.right.devtrq = devtrq.r;
    rob->wrist.ps.devtrq = devtrq.ps;

    // raw torques?
    if (ob->test_raw_torque) {
	volts.l = rob->wrist.left.test_volts;
	volts.r = rob->wrist.right.test_volts;
	volts.ps = rob->wrist.ps.test_volts;
    }

    oldvolts = volts;

    // preserve force orientation
    pfov.s = volts.l;
    pfov.e = volts.r;

    pfov = preserve_orientation(pfov, ob->wrist.rl_pfomax);
    pfov = preserve_orientation(pfov, ob->wrist.rl_pfotest);
    rob->wrist.left.volts = pfov.s;
    rob->wrist.right.volts = pfov.e;

    pspfov = volts.ps;
    if (!finite(pspfov)) pspfov = 0.0;
    pspfov = dbracket(pspfov, -ob->wrist.rl_pfomax, ob->wrist.rl_pfomax);
    pspfov = dbracket(pspfov, -ob->wrist.rl_pfotest, ob->wrist.rl_pfotest);

    rob->wrist.ps.volts = pspfov;

    // TODO impose thermal model

    volts_ratio.l = 1.0;
    volts_ratio.ps = 1.0;
    // voltages may have been attenuated, so attenuate torque values too.
    if (fabs(oldvolts.l) > 0.1) {
	volts_ratio.l = volts.l / oldvolts.l;
	ob->wrist.torque.aa *= volts_ratio.l;
	ob->wrist.torque.fe *= volts_ratio.l;
	ob->wrist.moment_cmd.fe *= volts_ratio.l;
	ob->wrist.moment_cmd.aa *= volts_ratio.l;
	rob->wrist.left.devtrq *= volts_ratio.l;
	rob->wrist.right.devtrq *= volts_ratio.l;
    }

    if (fabs(oldvolts.ps) > 0.1) {
	volts_ratio.ps = volts.ps / oldvolts.ps;
	ob->wrist.torque.ps *= volts_ratio.ps;
	ob->wrist.moment_cmd.ps *= volts_ratio.ps;
	rob->wrist.ps.devtrq *= volts_ratio.ps;
    }

    if (ob->have_planar_ao8) {
	// write voltages to daq
	uei_aout32_write(rob->wrist.uei_ao_board_handle,
		rob->wrist.left.ao_channel, rob->wrist.left.volts);
	uei_aout32_write(rob->wrist.uei_ao_board_handle,
		rob->wrist.right.ao_channel, rob->wrist.right.volts);
	uei_aout32_write(rob->wrist.uei_ao_board_handle,
		rob->wrist.ps.ao_channel, rob->wrist.ps.volts);
    } else if (ob->have_can) {
	s32 l, r, ps;

	l = rob->wrist.left.volts * 100.;
	r = rob->wrist.right.volts * 100.;
	ps = rob->wrist.ps.volts * 100.;

	can_mot_write(rob->wrist.left.ao_channel, l);
	can_mot_write(rob->wrist.right.ao_channel, r);
	can_mot_write(rob->wrist.ps.ao_channel, ps);
    }
}

void
wrist_after_compute_controls(void)
{
    // add wrist parameters (do whole structure at once)
    prev->wrist.pos = ob->wrist.pos;
    prev->wrist.vel = ob->wrist.vel;
    prev->wrist.fvel = ob->wrist.fvel;
    prev->wrist.right = rob->wrist.right;
    prev->wrist.left = rob->wrist.left;
    prev->wrist.ps = rob->wrist.ps;
}

void
wrist_set_zero_torque(void)
{
    // include wrist motor parameters
    ob->wrist.torque.fe = 0.0;
    ob->wrist.torque.aa = 0.0;
    ob->wrist.torque.ps = 0.0;
    rob->wrist.left.devtrq = 0.0;
    rob->wrist.right.devtrq = 0.0;
    rob->wrist.ps.devtrq = 0.0;
    rob->wrist.left.volts = 0.0;
    rob->wrist.right.volts = 0.0;
    rob->wrist.ps.volts = 0.0;
}

void
wrist_write_zero_torque(void)
{
    // include wrist motor parameters
    wrist_set_zero_torque();
    if (ob->have_planar_ao8) {
    uei_aout32_write(rob->wrist.uei_ao_board_handle,
	rob->wrist.left.ao_channel, 0.0);
    uei_aout32_write(rob->wrist.uei_ao_board_handle,
	rob->wrist.right.ao_channel, 0.0);
    uei_aout32_write(rob->wrist.uei_ao_board_handle,
	rob->wrist.ps.ao_channel, 0.0);
    } else if (ob->have_can) {
	can_mot_write(rob->wrist.left.ao_channel, 0);
	can_mot_write(rob->wrist.right.ao_channel, 0);
	can_mot_write(rob->wrist.ps.ao_channel, 0);
    }
}

void
wrist_check_safety(void)
{
	if (ob->safety.override) return;
	if ((fabs(ob->wrist.pos.fe) > 4.0)
	||  (fabs(ob->wrist.pos.aa) > 4.0)
	||  (fabs(ob->wrist.pos.ps) > 4.0)) {
// if (ob->paused == 0) {
//     do_error(ERR_WR_POS_CHECK);
// }
		ob->paused = 1;
	}
}

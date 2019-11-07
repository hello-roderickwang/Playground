// sensact.c - sensors and actuators
// part of the robot.o robot process

// convert from raw data taken from sensor inputs to useful formats
// convert from from useful formats to raw data to be sent to actuators

// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

#define As rob->shoulder.angle
#define Ae rob->elbow.angle
#define Ts rob->shoulder.torque
#define Te rob->elbow.torque
#define Vs rob->shoulder.vel
#define Ve rob->elbow.vel
#define G rob->grasp

// called after imt2.cal is read, to range check some shm vars
void
sensact_init(void)
{
    u32 i;

    if (ob->have_planar) ob->naxes = 2;
    if (ob->have_planar && ob->have_hand) ob->naxes = 3;
    if (ob->have_wrist) ob->naxes = 3;
    if (ob->have_ankle) ob->naxes = 2;

    if (ob->have_ft) {
	for (i = 0; i < 6; i++) {
	    rob->ft.channel[i] = ibracket(rob->ft.channel[i], 0, 63);
	}
    }
}

static void
planar_apply_safety_damping(void)
{
    f64 dx, dy;
    f64 xramp, yramp;
    f64 sramp;

    if (!ob->have_planar)
        return;
    dx = fabs(ob->pos.x - ob->safety.pos);
    dy = fabs(ob->pos.y - ob->safety.pos);

    // set up a ramp at the damping edge
    xramp = yramp = 1.0;
    // feather the edge of the safety zone.
    // safety.ramp is the width of the feathered edge.
    // don't divide by zero.
    sramp = ob->safety.ramp;
    if (sramp > .000001) {
        if (dx < sramp)
            xramp = dx / sramp;
        if (dy < sramp)
            yramp = dy / sramp;
    }

    ob->motor_force.x = -ob->safety.damping_nms * ob->vel.x * xramp;
    ob->motor_force.y = -ob->safety.damping_nms * ob->vel.y * yramp;
}

void
planar_check_safety(void)
{
    if (!ob->have_planar)
        return;
    // this isn't really for overriding safety.
    // it's for turning off the safety damping zone, which
    // is sometimes necessary for debugging.
    if (ob->safety.override)
        return;

    if (ob->pos.x <= -ob->safety.pos
        || ob->pos.x >= ob->safety.pos
        || ob->pos.y <= -ob->safety.pos
        || ob->pos.y >= ob->safety.pos
        || ob->vel.x <= -ob->safety.vel
        || ob->vel.x >= ob->safety.vel
        || ob->vel.y <= -ob->safety.vel || ob->vel.y >= ob->safety.vel
        // || ob->motor_volts.s <= -ob->safety.volts
        // || ob->motor_volts.s >= ob->safety.volts
        // || ob->motor_volts.e <= -ob->safety.volts
        // || ob->motor_volts.e >= ob->safety.volts
        ) {
        planar_apply_safety_damping();
        ob->safety.was_planar_damping = 1;
    } else {
        if (ob->safety.was_planar_damping) {
            ob->safety.planar_just_crossed_back = 1;
            ob->safety.was_planar_damping = 0;
        }
    }

    // if the velocity is impossibly fast,
    // it's probably a bad encoder, send no force.
    if (ob->vel.x <= -5.0 || ob->vel.x >= 5.0 || ob->vel.y <= -5.0 || ob->vel.y >= 5.0) {
        ob->motor_force.x = 0.0;
        ob->motor_force.y = 0.0;
        // should we pause?
        // ob->paused = 1;
    }
}

// when you come out of the damping field, have the voltage ramp up from
// zero to 100% in safety.damp_ret_secs seconds

se
planar_back_from_safety_damping(se volts)
{
    f64 x;
    u32 total_ticks;

    total_ticks = ob->safety.damp_ret_secs * ob->Hz;

    if (ob->safety.planar_just_crossed_back) {
        if (ob->safety.damp_ret_secs > 10.0 || ob->safety.damp_ret_secs <= 0.5)
            ob->safety.damp_ret_secs = 2.0;
        ob->safety.planar_just_crossed_back = 0;
        ob->safety.damp_ret_ticks = total_ticks;
    }
    // the damp ramp is done
    if (ob->safety.damp_ret_ticks <= 0) {
        ob->safety.damp_ret_ticks = 0;
        return volts;
    }
    // else ...
    // x is f64, between zero and one.

    x = (f64) (total_ticks - ob->safety.damp_ret_ticks)
        / total_ticks;

    if (x > 1.05)
        x = 0.0;
    if (x < 0.05)
        x = 0.0;

    volts.s = volts.s * x;
    volts.e = volts.e * x;
    ob->safety.damp_ret_ticks--;

    return volts;
}

// convert the encoder angles to x/y position.

// conversion A[se].xform from digital input to radians is 0.00009587.
// 0.00009587 == (pi * 2) / (2^^16)
// A[se].offset are calibration values reflecting the rotational position
// of the encoders in the motor housing.

void
encoder_sensor(void)
{
    se raw;

    se pr;
    xy pos;

    if (!ob->have_planar)
        return;

    if (ob->sim.sensors) {
        ob->pos = ob->sim.pos;
        return;
    }

    if (ob->have_can) {
        raw.s = As.raw = rob->can.pos_raw[As.channel];
        raw.e = Ae.raw = rob->can.pos_raw[Ae.channel];
    } else if (rob->pci4e.have) {
        raw.s = As.raw = (f64)rob->pci4e.raw[As.channel];
        raw.e = Ae.raw = (f64)rob->pci4e.raw[Ae.channel];
    } else if (ob->have_uei && !rob->pci4e.have) {
	raw.s = As.raw = (f64)daq->dienc[As.channel];
	raw.e = Ae.raw = (f64)daq->dienc[Ae.channel];
    }
// take the two raw shoulder/elbow values from the sensors
// and return an x/y coordinate pair
// applying polar to cartesian,
// polar offset xforms,
// and cartesian offset xforms.

    // translate
    // composite
    // cartesian

    // shoulder
    pr.s = As.rad = radian_normalize(xform1d(raw.s, As.xform, As.offset));
    As.deg = As.rad * 180. / M_PI;

    // elbow
    pr.e = Ae.rad = radian_normalize(xform1d(raw.e, Ae.xform, Ae.offset));
    Ae.deg = Ae.rad * 180. / M_PI;

    // these calibrations are negative of the encoder angle readings.
    As.cal = radian_normalize(-xform1d(raw.s, As.xform, 0.0));
    Ae.cal = radian_normalize(-xform1d(raw.e, Ae.xform, 0.0));

    pos = xy_polar_cartesian_2d(pr, rob->link);

    pos.x -= rob->offset.x;
    pos.y -= rob->offset.y;

    // inject errors for testing purposes

    if (ob->pos_error.mod && ((ob->i % ob->pos_error.mod) == 0)) {
        pos.x += ob->pos_error.dx;
        pos.y += ob->pos_error.dy;
    }

    ob->pos = pos;
}

// get velocity data, either from the tach on the servo
// or by calculating it from successive x/y positions.

// if you have a tach,
//
// L1 is the shoulder link (upper arm, upper motor).
// L2 is the elbow link (forearm, lower motor).
// the shoulder is above the elbow, like on a person's body (usually).
// note that in many of our hardware docs,
// motor#1 is elbow and motor#2 is shoulder.
// (that is, they are reversed.  oof.)

// theta is the motor's position in radians
// thetadot is the motor's angular velocity in radians/second.

// V = J * thetadot
// [Vx]   [-L1*sin(theta1)  -L2*sin(theta2) ]   [theta1dot]
// [  ] = [                                 ] * [         ]
// [Vy]   [ L1*cos(theta1)   L2*cos(theta2) ]   [theta2dot]

// thetadot = (theta - prevtheta) * sampfreq

void
tach_sensor(void)
{
    se theta;
    se pr;
    se dtheta;

    mat22 J;
    xy V;

    f64 Hz;
    f64 dtick;

    if (!ob->have_planar)
        return;

    theta.s = As.rad;
    theta.e = Ae.rad;

    ob->theta = theta;

    // later...
    // base Hz on measured delta_tick instead of constant Hz
    dtick = ob->times.time_delta_tick;
    if (dtick < 1.)
        dtick = 1.0;
    Hz = (1000. * 1000. * 1000.) / dtick;

    // if > 5x or < x/5, something is probably wrong.
    if ((Hz > (5 * ob->Hz)) || (Hz < (ob->Hz / 5)))
        Hz = ob->Hz;

    // uncomment this to do it the old constant way.
    Hz = (f64) ob->Hz;

    J = j_polar_cartesian_2d(ob->theta, rob->link);

    {
        f64 dtheta;
        // if no have_tach, use angles and butterworth

        // there is an initial spike, this is filtered out by ignoring
        // the first few cycles in the main loop

        // encoder values are [0..2pi].  To calculate velocity when
        // encoder crosses between 2pi and 0, we need -pi..pi,
        // that's delta_radian_normalize().

        dtheta = (ob->theta.s - prev->theta.s);
        ob->thetadot.s = delta_radian_normalize(dtheta) * Hz;
        pr.s = ob->fthetadot.s = butter(ob->thetadot.s, prev->thetadot.s, prev->fthetadot.s);

        dtheta = (ob->theta.e - prev->theta.e);
        ob->thetadot.e = delta_radian_normalize(dtheta) * Hz;
        pr.e = ob->fthetadot.e = butter(ob->thetadot.e, prev->thetadot.e, prev->fthetadot.e);

        // return this if no tach.
        ob->fsoft_vel = jacob2d_x_p2d(J, pr);
        V = ob->fsoft_vel;

        // or, if no have_tach, use x/y
        // no filter here

        ob->soft_vel.x = (ob->pos.x - prev->pos.x) * Hz;
        ob->soft_vel.y = (ob->pos.y - prev->pos.y) * Hz;
    }

    // encoder values are [0..2pi].  To calculate velocity when
    // encoder crosses between 2pi and 0, we need -pi..pi,
    // that's delta_radian_normalize().
    if (ob->have_can && ob->have_tach) {
        // convert raw counts from CAN reports to radial velocity
	// empirically (measured by dmd on 20130424) this actually behaves
	// WORSE than doing it ourselves, so we leave have_tach turned off.
        Vs.raw = rob->can.vel_raw[As.channel];
        dtheta.s = (Vs.raw + Vs.offset) * As.xform;
	ob->thetadot.s = delta_radian_normalize(dtheta.s);

        Ve.raw = rob->can.vel_raw[Ae.channel];
        dtheta.e = (Ve.raw + Ve.offset) * Ae.xform;
	ob->thetadot.e = delta_radian_normalize(dtheta.e);
    }
    else // no tach, use angles. This is what we really want to do (see above).
    {
        dtheta.s = (ob->theta.s - prev->theta.s);
        ob->thetadot.s = delta_radian_normalize(dtheta.s) * Hz;

        dtheta.e = (ob->theta.e - prev->theta.e);
        ob->thetadot.e = delta_radian_normalize(dtheta.e) * Hz;
    }

    // butterworth filter
    pr.s = ob->fthetadot.s = butter(ob->thetadot.s, prev->thetadot.s, prev->fthetadot.s);
    pr.e = ob->fthetadot.e = butter(ob->thetadot.e, prev->thetadot.e, prev->fthetadot.e);
    V = ob->fsoft_vel = jacob2d_x_p2d(J, pr);

    if (ob->sim.sensors) {
        V = ob->sim.vel;
    }

    ob->vel = V;

    ob->velmag = hypot(ob->vel.x, ob->vel.y);

    // we reset the positions when calibrating.
    // this jerks the positions, that would trigger this error.
    // this happens in test_raw_torque mode, so if so skip the check.

    if (!ob->test_raw_torque && ob->velmag > ob->safety.velmag_kick) {
	if (!ob->paused) {
	    // only warn once
	    notify_error("set-cal-dis", "Encoder kick detected. The robot has been paused and must be recalibrated.");
	}
	ob->paused = 1;
        do_error(ERR_PL_ENC_KICK);
    }

    ob->soft_accel.x = (ob->vel.x - prev->vel.x) * Hz;
    ob->soft_accel.y = (ob->vel.y - prev->vel.y) * Hz;
    ob->soft_accelmag = hypot(ob->soft_accel.x, ob->soft_accel.y);

    ob->soft_jerk.x = (ob->soft_accel.x - prev->soft_accel.x) * Hz;
    ob->soft_jerk.y = (ob->soft_accel.y - prev->soft_accel.y) * Hz;
    ob->soft_jerkmag = hypot(ob->soft_jerk.x, ob->soft_jerk.y);
}

// add vibration for testing.
// currently closed-loop only.
// note: if you experiment with this, be careful!
// <=1000 is treated specially, see second block.
// >1000 gives a light buzz, >3000 starts getting shaky.
// 20000 == 20 N deflection.
// 13 and 17 are numbers of samples, and they give us a vibration
// rate of 200/13 Hz in X and 200/17 Hz in Y, around 15 Hz.
// my milkshake brings all the bots to the yard.

void
vibrate(void)
{
    u32 vibrate;
    static s32 dx, dy;

    // ob->vibrate may change while the following block is running.
    vibrate = ob->vibrate;

    if (vibrate > 0 && vibrate <= 20000) {

        // shake with a smooth triangular sawtooth.
        if (vibrate > 1000) {
            dx = 6 - (ob->i % 13);               // -6 thru 6 sawtooth ///////
            if ((ob->i % 26) >= 13)
                dx = -dx;                        //       /\/\/\/
            dy = 8 - (ob->i % 17);               // -8 thru 8 sawtooth
            if ((ob->i % 34) >= 17)
                dy = -dy;
            dx = (vibrate / 1000.0) * (dx / 6.0);
            dy = (vibrate / 1000.0) * (dy / 8.0);
        }
        // below 1000 by 100's, shake at random,
        // bigger num is lower time freq.
        else if (vibrate >= 100 && vibrate <= 1000) {
            s32 mod;

            mod = (10 * ob->Hz) / vibrate;

            if ((ob->i % mod) == 0) {
                s32 rand(void);
                dx = 15 - (rand() % 31);
                dy = 15 - (rand() % 31);
            }
        }
    } else {
        dx = dy = 0;
    }
    ob->xvibe = dx;
    ob->yvibe = dy;
}

// check for sudden changes in motor command voltage
// if we change voltage too quickly, apply safety damping instead.

se
impulse_check(se volts)
{
    se dv;
    f64 impulse_thresh_volts;

    if (ob->impulse_thresh_volts <= 0.0) {
        impulse_thresh_volts = ob->pfomax;
    } else {
        impulse_thresh_volts = ob->impulse_thresh_volts;
    }

    dv.s = fabs(volts.s - prev->volts.s);
    dv.e = fabs(volts.e - prev->volts.e);

    prev->volts = volts;
    ob->dvolts = dv;

    if ((dv.s > impulse_thresh_volts) || (dv.e > impulse_thresh_volts)) {
        volts.s = volts.e = 0.0;
        planar_apply_safety_damping();
        ob->safety.was_planar_damping = 1;
    }

    return volts;
}

void
motor_temperature(Tm * tm, f64 volts)
{
    f64 amps;

    amps = volts * tm->trans_cond;

    // divisor checks
    if (tm->tmass_winding < .01)
        tm->tmass_winding = 100.0;
    if (tm->tmass_case < .01)
        tm->tmass_case = 100.0;
    if (tm->tres_winding < .0001)
        tm->tres_winding = .5;
    if (tm->tres_case < .0001)
        tm->tres_case = .5;

    tm->tmpr_winding = tm->tmpr_winding + (1. / tm->tmass_winding)
        * ((amps * amps * (1. + tm->tmpr_winding * tm->alpha) * tm->res0)
           - ((tm->tmpr_winding - tm->tmpr_case) / tm->tres_winding)) * ob->rate;
    tm->tmpr_case = tm->tmpr_case + (1. / tm->tmass_case)
        * (((tm->tmpr_winding - tm->tmpr_case) / tm->tres_winding)
           - (tm->tmpr_case / tm->tres_case)) * ob->rate;

    if (!finite(tm->tmpr_winding) || !finite(tm->tmpr_case)) {
        tm->tmpr_winding = 0.0;
        tm->tmpr_case = 0.0;
    }
}

// All the analog signals pass through a low-pass passive
// RC filters to eliminate spurious high frequency noise components
// (30 Hz breaking point).
//
// Torque actuators:  The maximum continuous torque we can command
// is +/- 10 Nm (limited by the servo amplifier circuitry).
// Allows nominal torque only

// [Ttheta1]   [-L1*sin(theta1)  L1*cos(theta1)]   [Fx]
// [       ] = [                               ] * [  ]
// [Ttheta2]   [-L2*sin(theta2)  L2*cos(theta2)]   [Fy]

void
dac_torque_actuator(void)
{
    printf("This is in dac_torque_actuator function.\n");
    se pr;
    se torque;
    se oldvolts, volts;
    f64 volts_ratio;

    mat22 Jp, Jt;

    Tm tm;
    f64 stmax, etmax, tmax;

    // have_planar = 1
    if (!ob->have_planar)
        return;
    // encoder angles
    pr.s = As.rad;
    pr.e = Ae.rad;

    printf("pr.s: %f\n", pr.s);
    printf("pr.e: %f\n", pr.e);

    Jp = j_polar_cartesian_2d(pr, rob->link);
    Jt = jacob2d_transpose(Jp);

    printf("motor_force.x: %f\n", ob->motor_force.x);
    printf("motor_force.y: %f\n", ob->motor_force.y);

    if (ob->vibrate) {
        ob->motor_force.x += ob->xvibe;
        ob->motor_force.y += ob->yvibe;
    }

    printf("after vibrate motor_force.x: %f\n", ob->motor_force.x);
    printf("after vibrate motor_force.y: %f\n", ob->motor_force.y);
	
    // arbitrary set motor_force.x/y
    ob->motor_force.x = 1;
    ob->motor_force.y = 1;
	
    printf("arbitrary motor_force.x: %f\n", ob->motor_force.x);
    printf("arbitrary motor_force.y: %f\n", ob->motor_force.y);

    // torque in Nm
    torque.s = ob->motor_force.x * Jt.e00 + ob->motor_force.y * Jt.e01;
    // torque volts
    volts.s = (torque.s - Ts.offset) / Ts.xform;

    torque.e = ob->motor_force.x * Jt.e10 + ob->motor_force.y * Jt.e11;
    volts.e = (torque.e - Te.offset) / Te.xform;

    printf("after computation volts.s: %f\n", volts.s);
    printf("after computation volts.e: %f\n", volts.e);
    printf("after computation torque.s: %f\n", torque.s);
    printf("after computation torque.e: %f\n", torque.e);

    // make sure volts.s/e will not be override
    ob->test_raw_torque = 0;
	
    // voltage override, for testing and calibrating motors.
    // this lets us send a constant voltage to each motor
    // in an open loop mode.
    if (ob->test_raw_torque) {
        // func.write_log = write_motor_test_fifo_sample_fn;
        // ob->logfnid = 1 is set in motor_test script now.
        volts.s = ob->raw_torque_volts.s;
        volts.e = ob->raw_torque_volts.e;
        torque.s = volts.s * Ts.xform + Ts.offset;
        torque.e = volts.e * Te.xform + Te.offset;
    }
    // bracket voltages, preserving force orientation

    // volts.s = 1;
    // volts.e = 1;
    // torque.s = 1;
    // torque.e = 1;

    printf("after override volts.s: %f\n", volts.s);
    printf("after override volts.e: %f\n", volts.e);
    printf("after override torque.s: %f\n", torque.s);
    printf("after override torque.e: %f\n", torque.e);

    // volts before attenuation, see below
    oldvolts = volts;

    volts = preserve_orientation(volts, ob->pfomax);

    // if you're testing, you can set this to something gentle

    volts = preserve_orientation(volts, ob->pfotest);

    volts = impulse_check(volts);

    // ramp voltages after return from safety damping
    // do this after pfo, so that the ramp is based on pfo voltages.
    volts = planar_back_from_safety_damping(volts);

    // have_thermal_model = 1
    if (ob->have_thermal_model) {
        tm = rob->shoulder.tm;
        stmax = ob->pfomax;
        if (tm.trange < .01)
            tm.trange = 10.0;
        if (tm.tmpr_winding > tm.max_tmpr) {
            if (tm.tmpr_winding > (tm.max_tmpr + tm.trange)) {
                stmax = ob->pfomax - tm.reduction;
            } else {
                stmax = ob->pfomax - (tm.reduction
                                      * ((tm.tmpr_winding - tm.max_tmpr) / tm.trange));
            }
        }

        tm = rob->elbow.tm;
        if (tm.trange < .01)
            tm.trange = 10.0;
        etmax = ob->pfomax;
        if (tm.tmpr_winding > tm.max_tmpr) {
            if (tm.tmpr_winding > (tm.max_tmpr + tm.trange)) {
                etmax = ob->pfomax - tm.reduction;
            } else {
                etmax = ob->pfomax - (tm.reduction
                                      * ((tm.tmpr_winding - tm.max_tmpr) / tm.trange));
            }
        }


        tmax = MIN(stmax, etmax);
        tmax = MIN(tmax, ob->pfomax);

        volts = preserve_orientation(volts, tmax);

        motor_temperature(&rob->shoulder.tm, volts.s);
        motor_temperature(&rob->elbow.tm, volts.e);
    }

    volts_ratio = 1.0;
    // voltages may have been attenuated, so attenuate torque values too.
    if (fabs(oldvolts.s) > 0.1) {
        volts_ratio = volts.s / oldvolts.s;
        torque.s *= volts_ratio;
        torque.e *= volts_ratio;
        ob->motor_force.x *= volts_ratio;
        ob->motor_force.y *= volts_ratio;
    }

    // have_ft = 0
    if (!ob->have_ft) {
        rob->ft.world.x = -ob->motor_force.x;
        rob->ft.world.y = -ob->motor_force.y;
        rob->ft.world.z = 0.0;
    }

    ob->motor_torque.s = torque.s;
    ob->motor_torque.e = torque.e;
    ob->motor_volts.s = volts.s;
    ob->motor_volts.e = volts.e;

    // write daqs
    // we have a number between -10 and 10 "volts"
    // convert it to a number between -32767 and 32767.
    // convert it to a number between -1000 and 1000.


    // have_uei = 0
    // have_planar_ao8 = 0
    if (ob->have_uei) {
	if (ob->have_planar_ao8) {
	    // new for planar ao8
	    uei_aout32_write(ob->planar_uei_ao_board_handle,
		rob->shoulder.torque.channel, ob->motor_volts.s);
	    uei_aout32_write(ob->planar_uei_ao_board_handle,
		rob->elbow.torque.channel, ob->motor_volts.e);
	} else {
	    // old for planar mf
	    uei_aout_write(ob->motor_volts.s, ob->motor_volts.e);
	}
	// have_can = 1
    } else if (ob->have_can) {
        s32 svalue, evalue;

        svalue = lround(ob->motor_volts.s * 100.);
        evalue = lround(ob->motor_volts.e * 100.);

        can_mot_write(rob->shoulder.torque.channel, svalue);
        can_mot_write(rob->elbow.torque.channel, evalue);
    }

}

void
planar_set_zero_torque(void)
{
    if (!ob->have_planar)
        return;
    ob->motor_force.x = 0.0;
    ob->motor_force.y = 0.0;
    ob->motor_torque.s = 0.0;
    ob->motor_torque.e = 0.0;
    ob->motor_volts.s = 0.0;
    ob->motor_volts.e = 0.0;
}

void
planar_write_zero_torque(void)
{
    if (!ob->have_planar)
        return;
    planar_set_zero_torque();
    if (ob->have_uei) {
	if (ob->have_planar_ao8) {
	    // new for planar ao8
	    uei_aout32_write(ob->planar_uei_ao_board_handle,
		rob->shoulder.torque.channel, 0.0);
	    uei_aout32_write(ob->planar_uei_ao_board_handle,
		rob->elbow.torque.channel, 0.0);
	} else {
	    // old for planar mf
	    uei_aout_write(0.0, 0.0);
	}
    } else if (ob->have_can) {
        can_mot_write(rob->shoulder.torque.channel, 0);
        can_mot_write(rob->elbow.torque.channel, 0);
    }
}

void
planar_after_compute_controls(void)
{
    if (!ob->have_planar)
        return;
    prev->pos = ob->pos;
    prev->vel = ob->vel;
    prev->theta = ob->theta;
    prev->thetadot = ob->thetadot;
    prev->fthetadot = ob->fthetadot;
    prev->tach_vel = ob->tach_vel;
    prev->ftach_vel = ob->ftach_vel;
    prev->soft_vel = ob->soft_vel;
    prev->fsoft_vel = ob->fsoft_vel;

    do_max();
}

void
do_max(void)
{
    ob->max.vel.x = MAX(ob->max.vel.x, ob->vel.x);
    ob->max.vel.y = MAX(ob->max.vel.y, ob->vel.y);
    ob->max.motor_force.x = MAX(ob->max.motor_force.x, ob->motor_force.x);
    ob->max.motor_force.y = MAX(ob->max.motor_force.y, ob->motor_force.y);
    ob->max.motor_torque.s = MAX(ob->max.motor_torque.s, ob->motor_torque.s);
    ob->max.motor_torque.e = MAX(ob->max.motor_torque.e, ob->motor_torque.e);
}

#define conv_lb_N 4.44822162
#define conv_inlb_Nm 0.112984829

static void ft_new_rotate(void);
static void ft_old_rotate(void);

void
adc_ft_sensor(void)
{
    // matrix multiply amd convert
    // rob->ft.raw strain gauge voltages to forces

    u32 i;
    // xy Fxy;
    // xyz dev;

    if (!ob->have_ft)
	return;

    // if have_ft and have_can, then it's atinetft.
    if (ob->have_can) {
	for (i = 0; i < 6; i++) {
	    // raw now comes from atinetft, which has internal filter
	    rob->ft.cooked[i] = rob->ft.raw[i];
	    rob->ft.curr[i] = rob->ft.cooked[i];
	    rob->ft.filt[i] = rob->ft.curr[i];
	}
    } else {
	// ISA FT code deleted.
	// have ATI or JR3 FT that talks to UEI DAQ board

	// curr has intermediate values, so don't use ft.curr
	f64 curr[6];

	for (i = 0; i < 6; i++) {
	    rob->ft.raw[i] = daq->adcvolts[rob->ft.channel[i]];
	    rob->ft.cooked[i] = rob->ft.raw[i]
		+ rob->ft.bias[i];
	}

	for (i = 0; i < 6; i++) {
	    u32 j;

	    curr[i] = 0;
	    for (j = 0; j < 6; j++) {
		curr[i] += (rob->ft.cal[i][j] * rob->ft.cooked[j]);
	    }
	}

	for (i = 0; i < 6; i++) {
	    f64 conv;
	    // u32 j;
	    // u32 mod;

	    if (i < 3)
		conv = conv_lb_N;
	    else
		conv = conv_inlb_Nm;

	    if (rob->ft.scale[i] == 0.0) rob->ft.scale[i] = 1.0;
	    rob->ft.curr[i] = conv * curr[i] / rob->ft.scale[i];

	    // butterworth filtered
	    rob->ft.but[i] = butter(rob->ft.curr[i], rob->ft.prev[i], rob->ft.prevf[i]);
	    rob->ft.prev[i] = rob->ft.curr[i];
	    rob->ft.prevf[i] = rob->ft.but[i];

	    // sav gol filtered avg
	    rob->ft.sg[i] = apply_filter(rob->ft.curr[i], rob->ft.sghist[i]);

#ifdef LATER
	    // butterworth stopband
	    rob->ft.bsrawhist[i][0] = rob->ft.curr[i];
	    rob->ft.bs[i] = butstop(rob->ft.bsrawhist[i], rob->ft.bsfilthist[i]);
#endif // LATER
	    rob->ft.filt[i] = rob->ft.but[i];
	    // rob->ft.filt[i] = rob->ft.bs[i];
	    // rob->ft.filt[i] = rob->ft.sg[i];
	}
    } // end UEI FT

    rob->ft.dev.x = rob->ft.filt[0];
    rob->ft.dev.y = rob->ft.filt[1];
    rob->ft.dev.z = rob->ft.filt[2];
    rob->ft.moment.x = rob->ft.filt[3];
    rob->ft.moment.y = rob->ft.filt[4];
    rob->ft.moment.z = rob->ft.filt[5];

    if (rob->ft.have_rotmat) {
	ft_new_rotate();
    } else {
	ft_old_rotate();
    }
}

// read 3 rot angles from the cal file.
// convert them into a 3x3 rotation matrix
// apply it to the dev space
// then use another matrix to apply link angles

static void
ft_new_rotate(void)
{
    f64 ca, cb, cc, sa, sb, sc;
    f64 x, y, z;
    f64 (*m)[3];
    f64 m2[3][3];
    f64 b;

    // prepare a 3d rotation matrix
    ca = cos(rob->ft.rot.z);
    cb = cos(rob->ft.rot.y);
    cc = cos(rob->ft.rot.x);
    sa = sin(rob->ft.rot.z);
    sb = sin(rob->ft.rot.y);
    sc = sin(rob->ft.rot.x);

    // this is an address assignment.
    m = rob->ft.rotmat;

    // matrix as equation 2.71, craig, intro to robotics
    // (ZYX Euler angles, chapter 2)
    m[0][0] = ca * cb;
    m[0][1] = ca * sb * sc - sa * cc;
    m[0][2] = ca * sb * cc + sa * sc;

    m[1][0] = sa * cb;
    m[1][1] = sa * sb * sc + ca * cc;
    m[1][2] = sa * sb * cc - ca * sc;

    m[2][0] = -sb;
    m[2][1] = cb * sc;
    m[2][2] = cb * cc;

    // ATI FT is righthand and skips this negation.
    if (rob->ft.righthand == 0) {
        // do this for JR3 FT, XxY=-Z, following left hand rule
        m[0][2] = -m[0][2];
        m[1][2] = -m[1][2];
        m[2][2] = -m[2][2];
    }
    // we are working with the filtered ft values
    x = rob->ft.filt[0];
    y = rob->ft.filt[1];
    z = rob->ft.filt[2];

    // multiply device.[xyz] by this 3x3 matrix, yielding rotated.xyz
    // then apply link angles
    rob->ft.pre_jac.x = m[0][0] * x + m[0][1] * y + m[0][2] * z;
    rob->ft.pre_jac.y = m[1][0] * x + m[1][1] * y + m[1][2] * z;
    rob->ft.pre_jac.z = m[2][0] * x + m[2][1] * y + m[2][2] * z;

    // factor in elbow link angle (which is in motion).
    b = Ae.rad;

    m2[0][0] = -sin(b);
    m2[0][1] = -cos(b);
    m2[0][2] = 0.;

    m2[1][0] = cos(b);
    m2[1][1] = -sin(b);
    m2[1][2] = 0.;

    m2[2][0] = 0.;
    m2[2][1] = 0.;
    m2[2][2] = 1.;

    // reusing the locals x,y,z here.
    x = rob->ft.pre_jac.x;
    y = rob->ft.pre_jac.y;
    z = rob->ft.pre_jac.z;

    // multiply device.[xyz] by this 3x3 matrix, yielding rotated.xyz
    // then apply link angles
    rob->ft.world.x = m2[0][0] * x + m2[0][1] * y + m2[0][2] * z;
    rob->ft.world.y = m2[1][0] * x + m2[1][1] * y + m2[1][2] * z;
    rob->ft.world.z = m2[2][0] * x + m2[2][1] * y + m2[2][2] * z;

    // note that torques are NOT rotated

}

static void
ft_old_rotate(void)
{
    xy Fxy;
    xyz dev;

    // for horizontally mounted FTs
    // with the link pointing straight back at the patient,
    // +x radiates from the arm.
    // +y is right
    // +z is up

    dev.x = rob->ft.filt[0];
    dev.y = rob->ft.filt[1];
    dev.z = rob->ft.filt[2];

    // this handles the FT mounted vertically at the end of the planar arm.
    // with the jr3 mounted vertically,
    // +x is right
    // +y is down
    // +z points from the arm

    if (rob->ft.vert) {
	dev.x = rob->ft.filt[2];
	dev.y = rob->ft.filt[0];
	dev.z = -rob->ft.filt[1];
    }

    // account for ft up/down orientation
    // (the flip code should be cleaner.)
    if (rob->ft.flip) {
	mat22 m;
	se xy;	// this is really an xy.
	f64 off;

	off=rob->ft.offset;

	xy.s = dev.x;
	xy.e = dev.y;

	m.e00 = cos(off);	m.e01 = sin(off);
	m.e10 = sin(off);	m.e11 = -cos(off);
	Fxy = jacob2d_x_p2d(m, xy);

	dev.x = Fxy.x;
	dev.y = Fxy.y;
	dev.z = -dev.z;
    }

    // now we have filtered FT data, from either an ISA or DAQ ATI FT.

    // transform from FT coordinates rob->ft.curr[0,1]
    // to F.world

    {
	f64 del0;
	f64 cosD, sinD;
	f64 cosA, sinA;
	f64 cosB, sinB;
	f64 Ls, Le;

	se torque_aux;

	se angles;
	mat22 Jt;		// dev, world space

	del0 = Ae.rad - As.rad;
	cosD = cos(del0), sinD = sin(del0);
	if (rob->ft.flip) {
	    // we already factored the offsets into
	    // the flipped angles before.  this is kludgy code,
	    // it should be better integrated.
	    cosA = cos(0.0);
	    sinA = sin(0.0);
	} else {
	    cosA = cos(rob->ft.offset);
	    sinA = sin(rob->ft.offset);
	}
	Ls = rob->link.s;
	Le = rob->link.e;
	cosB = cosA * cosD - sinA * sinD;
	sinB = sinA * cosD + cosA * sinD;

	torque_aux.s = (dev.x * sinB + dev.y * cosB) * Ls;
	torque_aux.e = (dev.x * sinA + dev.y * cosA) * Le;

	// dev space
	angles.s = As.rad;
	angles.e = Ae.rad;
	rob->ft.dev.x = rob->ft.filt[0];
	rob->ft.dev.y = rob->ft.filt[1];
	rob->ft.dev.z = rob->ft.filt[2];
	rob->ft.xymag = hypot(dev.x, dev.y);
	rob->ft.moment.x = rob->ft.filt[3];
	rob->ft.moment.y = rob->ft.filt[4];
	rob->ft.moment.z = rob->ft.filt[5];

	// world space
	Jt = j_polar_cartesian_2d(angles, rob->link);
	Jt = jacob2d_transpose(Jt);
	Jt = jacob2d_inverse(Jt);
	Fxy = jacob2d_x_p2d(Jt, torque_aux);

	rob->ft.world.x = Fxy.x;
	rob->ft.world.y = Fxy.y;

	if (rob->ft.vert) {
	    rob->ft.world.z = -rob->ft.filt[1];
	    return;
	}

	if (rob->ft.flip) {
	    rob->ft.world.z = -rob->ft.filt[2];
	} else {
	    rob->ft.world.z = rob->ft.filt[2];
	}
    }

    if (ob->have_linear) {
	rob->ft.world.x = rob->ft.dev.y;
	rob->ft.world.y = -rob->ft.dev.x;
	rob->ft.world.z = -rob->ft.dev.z;
    }
}

// called when "oversampling" the ft

void
fast_read_ft_sensor(void)
{
    adc_ft_sensor();
}

// set the bias array to the current ft voltages,
// "zeroing" the bias.
// gets called when rob->ft.dobias is set.

void
ft_zero_bias()
{
        s32 i;
        for (i = 0; i < 6; i++) {
                rob->ft.bias[i] = -rob->ft.raw[i];
        }
}

// Dustin's grasp sensor, both foam pad and strain gauge.
//

void
adc_grasp_sensor(void)
{
    if (!ob->have_grasp)
        return;

    G.raw = daq->adcvolts[G.channel];
    G.cal = G.raw * G.gain;
    // for foam grasp sensor
    // G.force = (G.raw * G.gain - G.bias) - rob->ft.xymag;
    // for strain gauge grasp sensor
    G.force = (G.raw * G.gain + G.bias);
}

// Analog Devices ADXL 105EM-3 3-axis accelerometer
// http://www.analog.com/en/prod/0,2877,ADXL105,00.html
//
// takes 5V as input
// returns between 0-5V for each of X,Y,Z.
// output V = .5*G + 2.5
//
// rough calibration: -1G = 2V and 1G = 3V.
// so a typical 0G bias is 2.5 V and xform is .5 V/G.
// device output voltage range: +/- 4G (.5V - 4.5V)

void
adc_accel_sensor(void)
{
    u32 i;

    if (!ob->have_accel)
        return;

    for (i = 0; i < 3; i++) {

        rob->accel.raw[i] = daq->adcvolts[rob->accel.channel[i]];
        rob->accel.curr[i] = (rob->accel.raw[i] - rob->accel.bias[i])
            / rob->accel.xform;

        rob->accel.filt[i] = butter(rob->accel.curr[i],
                                    rob->accel.prev[i], rob->accel.filt[i]);
        rob->accel.prev[i] = rob->accel.curr[i];
        rob->accel.prevf[i] = rob->accel.filt[i];
    }
}

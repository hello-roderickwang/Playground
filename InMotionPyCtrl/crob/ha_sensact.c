// ha_sensact.c - hand robot sensors and actuators
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
hand_init(void)
{
    // Rob structure
    rob->hand.motor.enc_channel = 0;
    rob->hand.motor.devfrc = 0.0;
    rob->hand.motor.xform = -5.0;
    rob->hand.motor.volts = 0.0;

    //    rob->hand.uei_ao_board_handle = 0;

    // Ob structure
    ob->hand.pos = 0.0;
    ob->hand.vel = 0.0;
    ob->hand.fvel = 0.0;
    ob->hand.force = 0.0;
    rob->hand.gears.offset = 0.033;
    rob->hand.gears.span = 0.39;

    // Prev structure
    prev->hand.pos = 0.0;
    prev->hand.vel = 0.0;
    prev->hand.fvel = 0.0;
}

void
hand_force(void)
{
    // the forces are equal and opposite, but we make the signs the same
    // so that the robot pushing out is positive
    // and the person squeezing is also positive.
    ob->hand.force = rob->hand.motor.devfrc;
}

// link data from encoder via motor to world coordinates
// pc7266 and pci4e are both counter cards, should have one or tother.
void
hand_sensor(void)
{
    if (!ob->have_hand)
        return;

    if (ob->sim.sensors) {
        ob->hand.pos = ob->sim.pos.y;
        rob->hand.motor.disp = 0;
        return;
    }
    if (!rob->pci4e.have && !ob->have_can)
	return;

    //    if (rob->pc7266.have) {
    //        rob->hand.motor.disp = rob->pc7266.enc[rob->hand.motor.enc_channel];
    // fix...
    //    }

    if (rob->pci4e.have) {
	rob->hand.motor.disp = rob->pci4e.enc[rob->hand.motor.enc_channel];
    }

    if (ob->have_can) {
        rob->hand.motor.disp = rob->can.pos_raw[rob->hand.motor.enc_channel]
	* rob->hand.gears.disp_xform;
    }
    // the disp is in radians.
    // pos will be linear transform to approx diameter.
    ob->hand.pos = rob->hand.motor.disp * rob->hand.gears.xform + rob->hand.gears.offset;

    hand_force();
}

// calculate velocity and filtered velocity
void
hand_calc_vel(void)
{
    if (!ob->have_hand)
        return;

    ob->hand.vel = (ob->hand.pos - prev->hand.pos) * ob->Hz;

    ob->hand.fvel = butter(ob->hand.vel, prev->hand.vel, prev->hand.fvel);
}

static void
uei_write_hand(f64 volts)
{
    //    uei_aout32_write(rob->hand.uei_ao_board_handle, rob->hand.motor.ao_channel, volts);
}

//
// convert from the force output of the controller (in world coordinates)
//      to voltage input to the actuators (in motor coordinates)
void
dac_hand_actuator(void)
{
    f64 volts;
    f64 devfrc;
    f64 pfov;

    if (!ob->have_hand)
        return;

    // device forces
    devfrc = rob->hand.motor.devfrc;

    // command voltages
    if (fabs(rob->hand.motor.xform) < .0000001)
        rob->hand.motor.xform = -1.0;
    volts = devfrc / rob->hand.motor.xform + rob->hand.motor.bias;

    // raw voltages?
    if (ob->test_raw_torque) {
        volts = rob->hand.motor.test_volts;
    }
    // preserve force orientation
    pfov = volts;
    if (!finite(pfov))
        pfov = 0.0;
    // pfov = preserve_orientation(pfov, ob->hand.pfomax);
    pfov = dbracket(pfov, -ob->hand.pfomax, ob->hand.pfomax);
    pfov = dbracket(pfov, -ob->hand.pfotest, ob->hand.pfotest);
    rob->hand.motor.volts = pfov;


    if (ob->have_uei) {
        if (ob->have_planar_ao8) {
            uei_aout32_write(rob->hand.uei_ao_board_handle,
                rob->hand.motor.ao_channel, rob->hand.motor.volts);
        }

    // write daqs
    // uei_write_hand(rob->hand.motor.volts);
    } else if (ob->have_can) {
        s32 value;

        // convert from volts -10.0..10.0 to -1000..1000
        value = rob->hand.motor.volts * 100.0;

        can_mot_write(rob->hand.motor.ao_channel, value);
    }

}

void
hand_after_compute_controls(void)
{
    // add hand parameters (do whole structure at once)
    prev->hand.pos = ob->hand.pos;
    prev->hand.vel = ob->hand.vel;
    prev->hand.fvel = ob->hand.fvel;
}

void
hand_set_zero_force(void)
{
    // include hand motor parameters
    rob->hand.motor.devfrc = 0.0;
    rob->hand.motor.volts = 0.0;
}

void
hand_write_zero_force(void)
{
    // include hand motor parameters
    hand_set_zero_force();
    if (ob->have_uei) {
        uei_write_hand(0.0);
    } else if (ob->have_can) {
        can_mot_write(rob->hand.motor.ao_channel, 0);
    }
}

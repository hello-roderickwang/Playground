// li_sensact.c - linear robot sensors and actuators
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
linear_init(void)
{
    // Rob structure
    rob->linear.motor.enc_channel = 0;
    rob->linear.motor.devfrc = 0.0;
    rob->linear.motor.xform = -5.0;
    rob->linear.motor.volts = 0.0;

    rob->linear.uei_ao_board_handle = 0;

    // Ob structure
    ob->linear.pos = 0.0;
    ob->linear.vel = 0.0;
    ob->linear.fvel = 0.0;
    ob->linear.force = 0.0;
    ob->linear.offset = -0.23;

    // Prev structure
    prev->linear.pos = 0.0;
    prev->linear.vel = 0.0;
    prev->linear.fvel = 0.0;
}

// link data from encoder via motor to world coordinates
// pc7266 and pci4e are both counter cards, should have one or tother.
void
linear_sensor(void)
{
    if (!ob->have_linear)
        return;

    if (ob->sim.sensors) {
        ob->linear.pos = ob->sim.pos.y;
        return;
    }

    if (!rob->pci4e.have && !rob->pc7266.have)
        return;

    if (rob->pc7266.have) {
        ob->linear.pos = -rob->pc7266.enc[rob->linear.motor.enc_channel]
            + ob->linear.offset;
        // fix...
    }
    // sensor reads + going down, -sign is to switch this.
    if (rob->pci4e.have) {
        ob->linear.pos = -rob->pci4e.enc[rob->linear.motor.enc_channel]
            + ob->linear.offset;
    }
    // positional limit switch
    rob->linear.motor.limit_volts = daq->adcvolts[rob->linear.motor.limit_channel];

    // for now, disp is pos, not a motor angle
    rob->linear.motor.disp = ob->linear.pos;

    if (ob->have_ft) {
        ob->linear.force = rob->ft.world.z;
    }
}

// calculate velocity and filtered velocity
void
linear_calc_vel(void)
{
    if (!ob->have_linear)
        return;

    ob->linear.vel = (ob->linear.pos - prev->linear.pos) * ob->Hz;

    ob->linear.fvel = butter(ob->linear.vel, prev->linear.vel, prev->linear.fvel);
}

static void
uei_write_linear(f64 volts)
{
    if ((rob->linear.motor.ao_channel & 1) == 0)
        uei_aout_write(0.0, volts);
    else
        uei_aout_write(volts, 0.0);
}

//
// convert from the force output of the controller (in world coordinates)
//      to voltage input to the actuators (in motor coordinates)
void
dac_linear_actuator(void)
{
    f64 volts;
    f64 devfrc;
    f64 pfov;

    if (!ob->have_linear)
        return;

    // device forces
    devfrc = rob->linear.motor.devfrc;

    // command voltages
    if (fabs(rob->linear.motor.xform) < .0000001)
        rob->linear.motor.xform = -1.0;
    volts = devfrc / rob->linear.motor.xform;

    // raw voltages?
    if (ob->test_raw_torque) {
        volts = rob->linear.motor.test_volts;
    }
    // preserve force orientation
    pfov = volts;
    if (!finite(pfov))
        pfov = 0.0;
    // pfov = preserve_orientation(pfov, ob->linear.pfomax);
    pfov = dbracket(pfov, -ob->linear.pfomax, ob->linear.pfomax);
    pfov = dbracket(pfov, -ob->linear.pfotest, ob->linear.pfotest);
    rob->linear.motor.volts = pfov;

    // write daqs
    // uei_aout32_write(rob->linear.uei_ao_board_handle,
    // rob->linear.motor.ao_channel, rob->linear.motor.volts);
    uei_write_linear(rob->linear.motor.volts);

}

void
linear_after_compute_controls(void)
{
    // add linear parameters (do whole structure at once)
    prev->linear.pos = ob->linear.pos;
    prev->linear.vel = ob->linear.vel;
    prev->linear.fvel = ob->linear.fvel;
}

void
linear_set_zero_force(void)
{
    // include linear motor parameters
    rob->linear.motor.devfrc = 0.0;
    rob->linear.motor.volts = 0.0;
}

void
linear_write_zero_force(void)
{
    // include linear motor parameters
    linear_set_zero_force();
    uei_write_linear(0.0);
}

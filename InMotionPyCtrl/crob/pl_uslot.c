// uslot.c -switchuser slot functions, to be modified by InMotion2 programmers
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

void simple_ctl(u32);
void point_box_ctl(u32);
void point_ctl(u32);
void damp_ctl(u32);
void rotate_ctl(u32);
void adap_ctl(u32);
void sine_ctl(u32);
void wrist_ctl(u32);
void ankle_ctl(u32);
void curl_ctl(u32);
void wrist_fn_ctl(u32);
void wrist_curl_ctl(u32);
void wrist_ps_ctl(u32);
void planar_fn_ctl(u32);
void planar_const_ctl(u32);
void ankle_point_ctl(u32);
//void linear_ctl(u32);
//void linear_point_ctl(u32);                      //Added: Pontus
void flasher_ctl(u32);
//void linear_adap_ctl(u32);
void wrist_adap_ctl(u32);
void wrist_ps_adap_ctl(u32);
void hand_ctl(u32);
void ao8test_sine_ctl(u32);
void wrist_ref_ctl(u32);
void planar_single_motor_ctl(u32);
void planar_single_motorxy_ctl(u32);
void planar_req_pos_ctl(u32);
void ankle_ped_ctl(u32);
void ankle_Fitts_ctl(u32);

void
init_slot_fns(void)
{
    ob->slot_fns[0] = simple_ctl;
    ob->slot_fns[1] = point_box_ctl;
    ob->slot_fns[2] = point_ctl;
    ob->slot_fns[3] = damp_ctl;
    ob->slot_fns[4] = rotate_ctl;
    ob->slot_fns[5] = adap_ctl;
    ob->slot_fns[6] = sine_ctl;
    ob->slot_fns[7] = wrist_ctl;
    ob->slot_fns[8] = ankle_ctl;
    ob->slot_fns[9] = curl_ctl;
    ob->slot_fns[10] = wrist_fn_ctl;
    ob->slot_fns[11] = wrist_curl_ctl;
    ob->slot_fns[12] = wrist_ps_ctl;
    ob->slot_fns[13] = planar_fn_ctl;
    ob->slot_fns[14] = planar_const_ctl;
    ob->slot_fns[15] = ankle_point_ctl;
    //    ob->slot_fns[16] = linear_ctl;
    //    ob->slot_fns[17] = linear_point_ctl;         //Added: Pontus
    //    ob->slot_fns[18] = flasher_ctl;
    //    ob->slot_fns[19] = linear_adap_ctl;
    ob->slot_fns[20] = wrist_adap_ctl;
    ob->slot_fns[21] = wrist_ps_adap_ctl;
    ob->slot_fns[22] = hand_ctl;
    ob->slot_fns[23] = ao8test_sine_ctl;
    ob->slot_fns[24] = wrist_ref_ctl;
    ob->slot_fns[25] = planar_single_motor_ctl;
    ob->slot_fns[26] = planar_single_motorxy_ctl;
    ob->slot_fns[27] = planar_req_pos_ctl;
    ob->slot_fns[28] = ankle_ped_ctl;
    ob->slot_fns[29] = ankle_Fitts_ctl;
}

#define X ob->pos.x
#define Y ob->pos.y
#define fX ob->motor_force.x
#define fY ob->motor_force.y
#define vX ob->vel.x
#define vY ob->vel.y

// when you get to the end of a slot and it doesn't stop,
// you might want to stiffen the controller, as a function of time.

// e.g., you want the slot to triple in stiffness over two seconds at 200Hz.
// call: slot_term_stiffen(id, 400, 3.0)

// note that this does not change the stiffness, it changes the x/y
// motor forces after they are calculated but before they are pfo'd.

static void
slot_term_stiffen(u32 id, u32 time, f64 imult)
{
    u32 termi;
    f64 mult;

    termi = ob->slot[id].termi;

    if (termi <= 0 || time <= 0 || imult < 0.0)
        return;

    if (termi > time)
        termi = time;

    mult = 1.0 + (termi * (imult - 1.0) / time);
    // new 5/06...
    // todo...
    // ob->stiffener = some f(imult, termi)
    // mult = (100.0 + ob->stiffener) / 100.0;

    fX *= mult;
    fY *= mult;
}

void
point_box_ctl(u32 id)
{

    f64 damp;

    damp = ob->damp;

    ob->ref.pos.x = ob->safety.pos;
    ob->ref.pos.y = ob->safety.pos;

    fX = -(ob->stiff * (X - ob->ref.pos.x)
           + damp * (vX - ob->ref.vel.x));

    fY = -(ob->stiff * (Y - ob->ref.pos.y)
           + damp * (vY - ob->ref.vel.y));

    if (!(X < -ob->safety.pos
          || X > ob->safety.pos || Y < -ob->safety.pos || Y > ob->safety.pos)) {
        fX = 0.0;
        fY = 0.0;
    }
}

void
damp_ctl(u32 id)
{


    f64 damp;

    damp = ob->damp;

    fX = -(damp * (vX));
    fY = -(damp * (vY));
}

void
point_ctl(u32 id)
{

    f64 damp;
    xy signval;

    signval.x = (2.0 / M_PI) * atan2(vX, ob->friction_gap);
    fX = -(ob->stiff * (X - ob->ref.pos.x)
           + ob->damp * (vX)
           + ob->friction * signval.x);

    signval.y = (2.0 / M_PI) * atan2(vY, ob->friction_gap);
    fY = -(ob->stiff * (Y - ob->ref.pos.y)
           + ob->damp * (vY)
           + ob->friction * signval.y);
}

// moving box controller
void
simple_ctl(u32 id)
// moving_box_ctl(u32 id)
{
    f64 x, y, w, h;                              // center x/y, width, height

    // minus, plus, minus,  plus
    f64 l, r, b, t;                              // left, right, bottom, top
    f64 lx, ly, lw, lh;                          // length b0 to b1.
    f64 w2, h2;

    u32 i, term;                                 // index and termination
    f64 damp;
    xy signval;                                  // for friction

    f64 fx, fy;                                  // intermediate values for fX and FY

    // calculate lengths
    lx = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    ly = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    ob->slot[id].bcur.point.x = x = ob->slot[id].b0.point.x + i_min_jerk(i, term, lx);
    ob->slot[id].bcur.point.y = y = ob->slot[id].b0.point.y + i_min_jerk(i, term, ly);

    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);
    ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i_min_jerk(i, term, lh);

    // wall lrtb
    w2 = w / 2.0;
    h2 = h / 2.0;
    l = x - w2;
    r = x + w2;
    b = y - h2;
    t = y + h2;

    damp = ob->damp;

    signval.x = (2.0 / M_PI) * atan2(vX, ob->friction_gap);
    signval.y = (2.0 / M_PI) * atan2(vY, ob->friction_gap);

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    fx = -(damp * vX + ob->friction * signval.x);
    fy = -(damp * vY + ob->friction * signval.y);

    // outside
    if (X < l)
        fx = -((ob->stiff * (X - l)) + (damp * vX) + (ob->friction * signval.x));
    if (X > r)
        fx = -((ob->stiff * (X - r)) + (damp * vX) + (ob->friction * signval.x));
    if (Y < b)
        fy = -((ob->stiff * (Y - b)) + (damp * vY) + (ob->friction * signval.y));
    if (Y > t)
        fy = -((ob->stiff * (Y - t)) + (damp * vY) + (ob->friction * signval.y));

    // inside
    if (X > l && X < r && Y > b && Y < t) {
        fx = -(damp * vX + (ob->friction * signval.x));
        fy = -(damp * vY + (ob->friction * signval.y));
    }
    fX = fx;
    fY = fy;
    slot_term_stiffen(id, 400, 3.0);
}

// rotating box controller
void
rotate_ctl(u32 id)
{
    // this controller normalizes the slot along the +X axis.
    // box0 is src point, box1 is dest point.
    // base-center is offset by -x/-y to (0,0)
    // and rotated to "3 o'clock" by the angle -rot,
    // so the base lies along the y axis,
    // the "width" along the (vertical) y axis,
    // and "height" pointing zero degrees to 3 o'clock.

    // all these are in normalized space:
    // (for the boxes, the x/y are normalized, the w/h are always normal)
    xy ncfvec;                                   // command force vector
    xy npos;                                     // manipulandum position
    xy nvel;                                     // rotated velocity
    box nmov;                                    // the moving box

    f64 left, right, bottom, top;

    // these are in world space
    xy end;                                      // b1-b0;
    xy off;                                      // offset (-b0)

    // these are space independent
    f64 dwidth;
    f64 w2;
    f64 rot;                                     // angle of rotation
    f64 hyp;                                     // hypotenuse

    u32 i, term;                                 // index and termination
    f64 damp, stiff;

    // x and y components of right triangle formed by b0/b1
    end.x = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    end.y = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;

    // yes, atan2 y,x and hypot x,y
    rot = atan2(end.y, end.x);
    hyp = hypot(end.x, end.y);

    // delta width
    dwidth = ob->slot[id].b1.w - ob->slot[id].b0.w;

    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // move the box from origin along +x in normal space
    // the current point is i/term along the length line
    // (you might make i/term a minimum jerk fn if you like)
    nmov.point.x = i_min_jerk(i, term, hyp);
    nmov.point.y = 0.0;                          // y does not move
    nmov.w = ob->slot[id].b0.w + i_min_jerk(i, term, dwidth);
    nmov.h = hyp - nmov.point.x;

    // +x slot
    // wall lrtb
    w2 = nmov.w / 2.0;

    left = nmov.point.x;
    right = nmov.point.x + nmov.h;
    bottom = nmov.point.y - w2;
    top = nmov.point.y + w2;

    damp = ob->damp;
    stiff = ob->stiff;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;

    // normalize manipulandum point/position
    off.x = -ob->slot[id].b0.point.x;
    off.y = -ob->slot[id].b0.point.y;
    npos = rotate2d(xlate2d(ob->pos, off), -rot);
    // normalize velocity vector
    nvel = rotate2d(ob->vel, -rot);

    // todo: normalize ft sensor vals for force feedback
    // todo: variable damping

    // calculate default command force vector
    ncfvec.x = -damp * nvel.x;
    ncfvec.y = -damp * nvel.y;

    // outside
    if (npos.x < left)
        ncfvec.x = -((stiff * (npos.x - left)) + (damp * nvel.x));
    if (npos.x > right)
        ncfvec.x = -((stiff * (npos.x - right)) + (damp * nvel.x));
    if (npos.y < bottom)
        ncfvec.y = -((stiff * (npos.y - bottom)) + (damp * nvel.y));
    if (npos.y > top)
        ncfvec.y = -((stiff * (npos.y - top)) + (damp * nvel.y));

    // inside
    if (npos.x > left && npos.x < right && npos.y > bottom && npos.y < top) {
        ncfvec.x = -damp * nvel.x;
        ncfvec.y = -damp * nvel.y;
    }
    // we have a normal force vector, rotate it back to world space.

    ob->motor_force = rotate2d(ncfvec, rot);

    slot_term_stiffen(id, 400, 3.0);
}

// not in use yet...
// initialize all pm variables.
// some need a big num, if they are mins

void
pl_pm_zero()
{
    ob->pm.active_power = 0.0;
    ob->pm.robot_power = 0.0;
    ob->pm.min_jerk_deviation = 0.0;
    ob->pm.min_jerk_dgraph = 0.0;
    ob->pm.jerkmag = 0.0;
    ob->pm.dist_straight_line = 0.0;
    ob->pm.max_dist_along_axis = 0.0;
    ob->pm.max_vel = 0.0;

    ob->pm.npoints = 0;

    // this is a min, so make it big.
    ob->pm.min_dist_from_target = 99.0;
}

// adaptive controller
// derived from rotate_ctl

// NOTE!  this controller does not follow the "morphing rectangle" paradigm
// of the other controllers.  it takes a starting x/y point and
// a finishing x/y point, and assumes that there is a collapsing slot
// between them.  this is strange and sad, but currently true.

void
adap_ctl(u32 id)
{
    // this controller normalizes the slot along the +X axis.
    // box0 is src point, box1 is dest point.
    // base-center is offset by -x/-y to (0,0)
    // and rotated to "3 o'clock" by the angle -rot,
    // so the base lies along the y axis,
    // the "width" along the (vertical) y axis,
    // and "height" pointing zero degrees to 3 o'clock.

    // all these are in normalized space:
    // (for the boxes, the x/y are normalized, the w/h are always normal)
    xy ncfvec;                                   // command force vector
    xy npos;                                     // manipulandum position
    xy nvel;                                     // rotated velocity
    xy nftforce;                                 // ft force
    xy nsignval;                                 // for friction
    box nmov;                                    // the moving box

    f64 left, right, bottom, top;

    xy ftvec;                                    // horizontal ft force vector

    // these are in world space
    xy end;                                      // b1-b0;
    xy off;                                      // offset (-b0)

    // these are space independent
    f64 dwidth;
    f64 w2;
    f64 rot;                                     // angle of rotation
    f64 hyp;                                     // hypotenuse

    u32 i, term;                                 // index and termination
    f64 damp, stiff, side_stiff;

    f64 dist_from_target;

    // x and y components of right triangle formed by b0/b1
    end.x = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    end.y = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;

    // yes, atan2 y,x and hypot x,y
    rot = atan2(end.y, end.x);
    hyp = hypot(end.x, end.y);

    // delta width
    dwidth = ob->slot[id].b1.w - ob->slot[id].b0.w;

    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // move the box from origin along +x in normal space
    // the current point is i/term along the length line
    // (you might make i/term a minimum jerk fn if you like)
    nmov.point.x = i_min_jerk(i, term, hyp);
    nmov.point.y = 0.0;                          // y does not move
    nmov.w = ob->slot[id].b0.w + i_min_jerk(i, term, dwidth);
    nmov.h = hyp - nmov.point.x;

    // +x slot
    // wall lrtb
    w2 = nmov.w / 2.0;

    left = nmov.point.x;
    right = nmov.point.x + nmov.h;
    bottom = nmov.point.y - w2;
    top = nmov.point.y + w2;

    damp = ob->damp;
    stiff = ob->stiff;
    side_stiff = ob->side_stiff;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;

    // normalize manipulandum point/position
    off.x = -ob->slot[id].b0.point.x;
    off.y = -ob->slot[id].b0.point.y;
    npos = rotate2d(xlate2d(ob->pos, off), -rot);
    // normalize velocity vector
    nvel = rotate2d(ob->vel, -rot);
    // normalize ft force
    ftvec.x = rob->ft.world.x;
    ftvec.y = rob->ft.world.y;
    nftforce = rotate2d(ftvec, -rot);

    ob->norm.x = npos.x;
    ob->back.x = nmov.point.x;

    // performance metrics

// comments from adapctr2.cpp

// pm1 : initialization
// pm2a: sum of power along target axis
// pm2b: sum of deviation from min. jerk pos
// pm3 : sum of (distance normal to target axis)^2
// pm4 : max distance along target axis
// npts: number of points in the above sums

// ngvec[4+11*game_n] = ngvec[4+11*game_n] + sFx*sVx; // PM2a
// ngvec[5+11*game_n] = ngvec[5+11*game_n] + sX-lmw; // PM2b
// ngvec[6+11*game_n] = ngvec[6+11*game_n] + sY*sY; // PM3
// if (fabs(sX) > ngvec[7+11*game_n]) ngvec[7+11*game_n] = fabs(sX); // PM4
// ngvec[8+11*game_n]++; // npts

    // note that these pm.things are all state, except for npoints
    // npoints must be zeroed to init, the rest need not be zeroed.

    if (npos.x > nmov.point.x) {
        ob->pm.active_power += 0;
        ob->pm.min_jerk_deviation += fabs(npos.x - nmov.point.x);       // pm2b
    } else {
        ob->pm.active_power += (nvel.x * nftforce.x);   // pm2a
        ob->pm.robot_power += (fabs(nvel.x * nftforce.x));      // pm2a
        ob->pm.min_jerk_deviation += 0;
    }

    ob->pm.min_jerk_dgraph += fabs(npos.x - nmov.point.x);      // graph
    ob->pm.jerkmag += ob->soft_jerkmag;
    ob->pm.dist_straight_line += (npos.y * npos.y);     // pm3

    if (ob->pm.max_dist_along_axis < fabs(npos.x))
        ob->pm.max_dist_along_axis = fabs(npos.x);      // pm4

    if (ob->pm.max_vel < ob->velmag)
        ob->pm.max_vel = ob->velmag;

    dist_from_target = fabs(hyp - npos.x);
    if (ob->pm.min_dist_from_target > dist_from_target)
        ob->pm.min_dist_from_target = dist_from_target;
    ob->pm.npoints++;                            // npts

    // todo: normalize ft sensor vals for force feedback
    // todo: variable damping

    nsignval.x = atan2(nvel.x, ob->friction_gap);
    nsignval.y = atan2(nvel.y, ob->friction_gap);

    // calculate default command force vector
    ncfvec.x = -(damp * nvel.x + (ob->friction * nsignval.x));
    ncfvec.y = -(damp * nvel.y + (ob->friction * nsignval.y));

    // outside
    if (npos.x < left)
        ncfvec.x = -((stiff * (npos.x - left)) + (damp * nvel.x) + (ob->friction * nsignval.x));
    if (npos.x > right)
        ncfvec.x = -((stiff * (npos.x - right)) + (damp * nvel.x) + (ob->friction * nsignval.x));
    if (npos.y < bottom)
        ncfvec.y = -((side_stiff * (npos.y - bottom)) + (damp * nvel.y) + (ob->friction * nsignval.y));
    if (npos.y > top)
        ncfvec.y = -((side_stiff * (npos.y - top)) + (damp * nvel.y) + (ob->friction * nsignval.y));

    // inside
    if (npos.x > left && npos.x < right && npos.y > bottom && npos.y < top) {
        ncfvec.x = -(damp * nvel.x + (ob->friction * nsignval.x));
        ncfvec.y = -(damp * nvel.y + (ob->friction * nsignval.y));
    }
    // we have a normal force vector, rotate it back to world space.

    ob->motor_force = rotate2d(ncfvec, rot);
    slot_term_stiffen(id, 400, 3.0);
}

//
// sine_ctl
// output an open loop sine wave.
// test_raw_torque must be set.
//
void
sine_ctl(u32 id)
{
    f64 x, v, sv, ev;

    if (!ob->test_raw_torque)
        return;

    x = (ob->Hz * ob->sin_period);
    if (x <= 0.0)
        x = 1.0;
    x = ob->i * (2.0 * M_PI) / x;
    v = sin(x) * ob->sin_amplitude;

    sv = 0.0;
    if (ob->sin_which_motor & 1)
        sv = v;
    ob->raw_torque_volts.s = sv;
    ev = 0.0;
    if (ob->sin_which_motor & 2)
        ev = v;
    ob->raw_torque_volts.e = ev;
}

//
// ao8test_sine_ctl
// output an open loop sine wave.
// sent outputs to ao8 channels for testing
// send to a channel if its corresponding scr 1 bit is set
// set aodiff to measured volts - outvolts
//
void
ao8test_sine_ctl(u32 id)
{
    f64 x, x2, v, volts;
    f64 lastx2, lastv;
    s32 i;
    u32 bits;

    if (!ob->test_no_torque)
        return;

    x = (ob->Hz * ob->sin_period);
    if (x <= 0.0)
        x = 1.0;
    x2 = ob->i * (2.0 * M_PI) / x;
    // scr[0] is the voltage we send out.
    ob->scr[0] = v = sin(x2) * ob->sin_amplitude;

    // it looks like it takes 2 samples to get the data in sync.
    // scr[2] is the fudge factor for this.
    lastx2 = (ob->i + ob->scr[2]) * (2.0 * M_PI) / x;
    lastv = sin(lastx2) * ob->sin_amplitude;

    // the bit mask
    bits = ob->scr[1];

    for (i = 0; i < 8; i++) {
        volts = 0.0;
        if ((bits >> i) & 1) {
            volts = v;
        }
        //        uei_aout32_write(ob->planar_uei_ao_board_handle, i, volts);
    }

    // i hope this gives the signals enough time to settle
    for (i = 0; i < 8; i++) {
        volts = 0.0;
        if ((bits >> i) & 1) {
            volts = lastv;
        }
        // first or second bank of 8 ains
        if (ob->scr[3]) {
            ob->aodiff[i] = daq->adcvolts[i + 8] - volts;
        } else {
            ob->aodiff[i] = daq->adcvolts[i] - volts;
        }
        // prime the pump to ignore artifacts when we change freqs
        if (ob->aocount > (fabs(ob->scr[2]) + 2)) {
            ob->aocum[i] += (ob->aodiff[i] * ob->aodiff[i]);
            ob->aorms[i] = sqrt(ob->aocum[i] / ob->aocount);
        } else {
            ob->aocum[i] = 0.0;
            ob->aorms[i] = 0.0;
        }
    }
    ob->aocount++;
}

// curl controller
// with x=vy y=-vx, and +curl, it rotates cw. -curl rotates ccw.

void
curl_ctl(u32 id)
{

    f64 curl;
    f64 damp;

    curl = ob->curl;
    damp = ob->damp;

    fX = (curl * (vY)) - (damp * (vX));
    fY = -(curl * (vX)) - (damp * (vY));
}

static f64
pl_i_ref_fn(u32 i, u32 term, f64 phase, f64 amplitude)
{
    return amplitude * cos((2.0 * M_PI * i / term) + phase);
}

// planar function contrller
void
planar_fn_ctl(u32 id)
{
    f64 x, y, w, h;                              // center x/y, width, height

    // minus, plus, minus,  plus
    f64 l, r, b, t;                              // left, right, bottom, top
    f64 lx, ly, lw, lh;                          // length b0 to b1.
    f64 w2, h2;

    u32 i, term;                                 // index and termination
    f64 damp;

    f64 fx, fy;                                  // intermediate values for fX and FY

    // calculate lengths
    lx = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    ly = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    ob->slot[id].bcur.point.x = x = ob->slot[id].b0.point.x +
        pl_i_ref_fn(i, term, 0., 0.1);
    ob->slot[id].bcur.point.y = y = ob->slot[id].b0.point.y +
        pl_i_ref_fn(i, term, M_PI / 2.0, 0.1);

    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i * lw / term;
    ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i * lh / term;

    // wall lrtb
    w2 = w / 2.0;
    h2 = h / 2.0;
    l = x - w2;
    r = x + w2;
    b = y - h2;
    t = y + h2;



    damp = ob->damp;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;
    fx = -damp * vX;
    fy = -damp * vY;

    // outside
    if (X < l)
        fx = -((ob->stiff * (X - l)) + (damp * vX));
    if (X > r)
        fx = -((ob->stiff * (X - r)) + (damp * vX));
    if (Y < b)
        fy = -((ob->stiff * (Y - b)) + (damp * vY));
    if (Y > t)
        fy = -((ob->stiff * (Y - t)) + (damp * vY));

    // inside
    if (X > l && X < r && Y > b && Y < t) {
        // fx = 0.0;
        // fy = 0.0;
        fx = -damp * vX;
        fy = -damp * vY;
    }
    fX = fx;
    fY = fy;
    // ob->scr[0] = X;
    // ob->scr[1] = Y;
    // ob->scr[2] = l;
    // ob->scr[3] = b;
    // ob->scr[4] = r;
    // ob->scr[5] = t;
    // ob->scr[6] = i;
    slot_term_stiffen(id, 400, 3.0);
}

// constant force contrller

void
planar_const_ctl(u32 id)
{
    fX = ob->const_force.x;
    fY = ob->const_force.y;
}

// point control single motors independently
void
planar_single_motor_ctl(u32 id)
{
    if (!ob->test_raw_torque)
        return;

    if (ob->tvibamp < 0.0)
        ob->tvibamp = 0.0;
    if (ob->tvibamp > 5.0)
        ob->tvibamp = 5.0;
    ob->tsvibe = ((fabs(rand()) / RAND_MAX) - .5) * 2 * ob->tvibamp;
    ob->tevibe = ((fabs(rand()) / RAND_MAX) - .5) * 2 * ob->tvibamp;

    // the xforms have different signs, so so do these
    ob->spring.disp.s = delta_radian_normalize(ob->theta.s - ob->spring.ref.s);
    ob->raw_torque_volts.s = (-ob->spring.stiff.s * ob->spring.disp.s) + ob->tsvibe;
    ob->raw_torque_volts.s = dbracket(ob->raw_torque_volts.s, -10.0, 10.0);

    ob->spring.disp.e = delta_radian_normalize(ob->theta.e - ob->spring.ref.e);
    ob->raw_torque_volts.e = (ob->spring.stiff.e * ob->spring.disp.e) + ob->tevibe;
    ob->raw_torque_volts.e = dbracket(ob->raw_torque_volts.e, -10.0, 10.0);
}

// point control single motors independently by xy
void
planar_single_motorxy_ctl(u32 id)
{
    if (ob->tvibamp < 0.0)
        ob->tvibamp = 0.0;
    if (ob->tvibamp > 5.0)
        ob->tvibamp = 5.0;
    ob->txvibe = ((fabs(rand()) / RAND_MAX) - .5) * 2 * ob->tvibamp;
    ob->tyvibe = ((fabs(rand()) / RAND_MAX) - .5) * 2 * ob->tvibamp;

    fX = -(ob->stiff * (X - ob->ref.pos.x)
           + ob->damp * (vX - ob->ref.vel.x)) + ob->txvibe;
    ob->spring.dispxy.x = fabs(X - ob->ref.pos.x);

    fY = -(ob->stiff * (Y - ob->ref.pos.y)
           + ob->damp * (vY - ob->ref.vel.y)) + ob->tyvibe;
    ob->spring.dispxy.y = fabs(Y - ob->ref.pos.y);
}

// get desired point from user mode mouse
void
planar_req_pos_ctl(u32 id)
{

    f64 damp;

    damp = ob->damp;

    fX = -(ob->stiff * (X - ob->req_pos.x)
           + damp * (vX - ob->ref.vel.x));

    fY = -(ob->stiff * (Y - ob->req_pos.y)
           + damp * (vY - ob->ref.vel.y));
}


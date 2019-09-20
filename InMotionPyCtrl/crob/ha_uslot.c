// ha_uslot.c - hand robot useslot functions,
// to be modified by InMotion2 programmers
// part of the robot.o robot process
//
// InMotion2 robot system software

// Copyright 2003-2005 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"
// #include "uei_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

//Define position, velocity and force parameters in world coordinates.
//In this function, uppercase (lowercase) letters refer to actual (desired) parameters.
//
#define X ob->hand.pos
#define vX ob->hand.fvel
#define fX rob->hand.motor.devfrc

// when you get to the end of a slot and it doesn't stop,
// you might want to stiffen the controller, as a function of time.

// e.g., you want the slot to triple in stiffness over two seconds at 200Hz.
// call: slot_term_stiffen(id, 400, 2.0)

// note that this does not change the stiffness, it changes the x/y
// motor forces after they are calculated but before they are pfo'd.

static void
ha_slot_term_stiffen(u32 id, u32 time, f64 imult)
{
    u32 termi;
    f64 mult;

    termi = ob->slot[id].termi;

    if (termi <= 0 || time <= 0 || imult < 0.0)
        return;

    if (termi > time)
        termi = time;

    mult = 1.0 + (termi * (imult - 1.0) / time);

    fX *= mult;
}

// 1-D moving box controller for hand
void
hand_ctl(u32 id)
{

    f64 x, w;
    f64 l, r;                                    // left, right (meaning in, out)

    u32 i, term;                                 // index and termination
    f64 stiff, damp;

    f64 lx, lw;
    f64 w2;

    f64 fx;                                      // intermediate values for fX

    if (!ob->have_hand)
        return;

    // calculate travel length and intermediate box dimension parameters
    lx = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // current desired  box: x coordinates and width
    ob->slot[id].bcur.point.x = x = ob->slot[id].b0.point.x + i_min_jerk(i, term, lx);
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);

    // coordinates of left and right of current desired box
    // done??

    // wall lrtb
    w2 = w / 2.0;
    l = x - w2;
    r = x + w2;

    stiff = ob->hand.stiff;
    damp = ob->hand.damp;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    fx = -damp * vX;

    // outside
    if (X < l)
        fx = -((stiff * (X - l)) + (damp * vX));
    if (X > r)
        fx = -((stiff * (X - r)) + (damp * vX));

    // inside
    if (X > l && X < r) {
        fx = -damp * vX;
    }
    fX = fx;

    // post slot stiffen
    ha_slot_term_stiffen(id, 400, 1.25);

    // mini metric
    // if the robot is ahead of the desired, accumulate run in active_power.
    // the active_power value will be between 0.0 and the hand slot length
    if (lx > 0.0) {
        if (X > l) {
            ob->hand.active_power += fabs(X - prev->hand.pos);
        }
    } else {
        if (X < r) {
            ob->hand.active_power += fabs(X - prev->hand.pos);
        }
    }
    ob->hand.npoints++;                          // npts
}

//
// hand adaptive controller
// derived from planar adaptive
void
hand_adap_ctl(u32 id)
{

    f64 x, w;
    f64 l, r;                                    // left, right

    u32 i, term;                                 // index and termination
    f64 stiff, damp;

    f64 lx, lw;
    f64 w2;

    f64 fx;                                      // intermediate values for fX

    if (!ob->have_hand)
        return;

    // calculate travel lengths and intermediate box dimension parameters
    lx = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // current desired  box: x and width
    ob->slot[id].bcur.point.x = x = ob->slot[id].b0.point.x + i_min_jerk(i, term, lx);
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);

    // coordinates of left and right of current desired box
    // done??

    // wall lr
    w2 = w / 2.0;
    l = x - w2;
    r = x + w2;

    stiff = ob->hand.stiff;
    damp = ob->hand.damp;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    fx = -damp * vX;

    // outside
    if (X < l)
        fx = -((stiff * (X - l)) + (damp * vX));
    if (X > r)
        fx = -((stiff * (X - r)) + (damp * vX));

    // inside
    if (X > l && X < r) {
        fx = -damp * vX;
    }
    fX = fx;

    ha_slot_term_stiffen(id, 400, 1.25);

    // performance metrics

    // is this slot going up (+x) or down (-x)
    ob->hand.adap_going_up = 1;
    if (lx < 0.0) {
        ob->hand.adap_going_up = 0;
    }
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
    // ob->pm.active_power += (vX * ob->hand.force); // pm2a

    // do we need this?
    // if (ob->hand.adap_going_up)

    ob->pm.active_power += (vX * rob->ft.world.z);      // pm2a

    ob->pm.min_jerk_deviation += fabs(X - x);    // pm2b
    // for hand, use force instead?
    // ob->pm.dist_straight_line += (npos.y * npos.y); // pm3
    if (ob->pm.max_dist_along_axis < fabs(X))
        ob->pm.max_dist_along_axis = fabs(X);    // pm4
    ob->pm.npoints++;                            // npts
}

void
hand_point_ctl(u32 id)
{

    f64 stiff, damp;
    f64 force_bias;

    // force_bias = -11.0;
    force_bias = 0.0;

    stiff = ob->hand.stiff;
    damp = ob->hand.damp;

    fX = -((stiff * (X - ob->hand.ref_pos)) + (damp * vX)) + force_bias;
}

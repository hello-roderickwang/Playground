// wr_uslot.c - wrist robot user slot functions,
// to be modified by InMotion2 programmers
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

// define position, velocity and torque parameters in world coordinates.
// in this function, uppercase (lowercase) letters refer to
// actual (desired) parameters.

#define FE ob->wrist.pos.fe
#define AA ob->wrist.pos.aa
#define PS ob->wrist.pos.ps
#define OFE ob->wrist.fvel.fe                    // "O" stands for omega, meaning angular velocity
#define OAA ob->wrist.fvel.aa
#define OPS ob->wrist.fvel.ps
#define TFE ob->wrist.torque.fe
#define TAA ob->wrist.torque.aa
#define TPS ob->wrist.torque.ps

// when you get to the end of a slot and it doesn't stop,
// you might want to stiffen the controller, as a function of time.

// e.g., you want the slot to triple in stiffness over two seconds at 200Hz.
// call: slot_term_stiffen(id, 400, 3.0)

// note that this does not change the stiffness, it changes the x/y
// motor forces after they are calculated but before they are pfo'd.

static void
wr_slot_term_stiffen_2d(u32 id, u32 time, f64 imult)
{
    u32 termi;
    f64 mult;
    f64 dmult;
    f64 dstiff;

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

    // this is the effective diff stiffness after term_stiffen.
    dstiff = ob->wrist.diff_stiff * mult;
    // make sure it doesn't get greater than 35.
    dmult = mult;
    if (dstiff > 35.0) {
        dmult = mult * 35. / dstiff;
    }

    TFE *= dmult;
    TAA *= dmult;
}

static void
wr_slot_term_stiffen_ps(u32 id, u32 time, f64 imult)
{
    u32 termi;
    f64 mult;
    f64 psmult;
    f64 psstiff;

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

    // this is the effective ps stiffness after term_stiffen.
    psstiff = ob->wrist.ps_stiff * mult;
    // make sure it doesn't get greater than 35.
    psmult = mult;
    if (psstiff > 65.0) {
        psmult = mult * 65. / psstiff;
    }

    TPS *= psmult;
}

// re nocenter3d:
// the original wrist slot control code would run one controller at a time,
// with true control on only 1 (ps) or 2 (diff) axes.  the uncontrolled axes
// would be "stabilized" with a point controller that centered them.

// in newer code, we want to run more complicated controls, often with calls to
// multiple slot controllers.  In these cases, we do not want the uncontrolled
// axes stabilized, we want them untouched.

// if we want the other axes uncentered, we need to set the
// ob->wrist.nocenter3d variable to non-zero.

// 2-D moving box controller for wrist
void
wrist_ctl(u32 id)
{

    f64 fe, aa, w, h;                            // center fe/aa, width, height
    f64 l, r, b, t;                              // left, right, bottom, top sides of box
    f64 lfe, laa, lw, lh;                        // length b0 to b1.

    u32 i, term;                                 // index and termination

    f64 tfe, taa, tps;                           // intermediate values for fX and FY

    if (!ob->have_wrist)
        return;

    // calculate travel lengths in fe and aa directions and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lfe = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    laa = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // box xywh
    // current desired  box: fe and aa coordinates as well as width and height
    fe = ob->slot[id].b0.point.x + i_min_jerk(i, term, lfe);
    aa = ob->slot[id].b0.point.y + i_min_jerk(i, term, laa);
    w = ob->slot[id].bcur.w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);
    h = ob->slot[id].bcur.h = ob->slot[id].b0.h + i_min_jerk(i, term, lh);

    // coordinates of left, right, top, and bottom sides of current desired box
    l = fe - w / 2.0;
    r = fe + w / 2.0;
    b = aa - h / 2.0;
    t = aa + h / 2.0;

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;
    tfe = -ob->wrist.diff_damp * OFE;
    taa = -ob->wrist.diff_damp * OAA;

    // outside
    if (FE < l)
        tfe = -((ob->wrist.diff_stiff * (FE - l)) + (ob->wrist.diff_damp * OFE));
    if (FE > r)
        tfe = -((ob->wrist.diff_stiff * (FE - r)) + (ob->wrist.diff_damp * OFE));
    if (AA < b)
        taa = -((ob->wrist.diff_stiff * (AA - b)) + (ob->wrist.diff_damp * OAA));
    if (AA > t)
        taa = -((ob->wrist.diff_stiff * (AA - t)) + (ob->wrist.diff_damp * OAA));

    // inside
    if (FE > l && FE < r && AA > b && AA < t) {
        // fx = 0.0;
        // fy = 0.0;
        tfe = -ob->wrist.diff_damp * OFE;
        taa = -ob->wrist.diff_damp * OAA;
    }
    // for now, stiffen ps while controlling fe/aa
    tps = (ob->wrist.ps_stiff * PS + ob->wrist.ps_damp * OPS);

    TFE = tfe;
    TAA = taa;
    if (!ob->wrist.nocenter3d) {
        TPS = -tps;
    }

    // do not stiffen 2d for now
    wr_slot_term_stiffen_2d(id, 400, 1.0);
    if (!ob->pm.five_d) {
        wr_slot_term_stiffen_ps(id, 400, 2.0);
    }
}

static f64
wrist_i_ref_fn(u32 i, u32 term, f64 phase, f64 amplitude)
{
    return amplitude * cos((2.0 * M_PI * i / term) + phase);
}

// wrist controller with supplied function
void
wrist_fn_ctl(u32 id)
{

    f64 fe, aa, w, h;                            // center fe/aa, width, height
    f64 l, r, b, t;                              // left, right, bottom, top sides of box
    f64 lfe, laa, lw, lh;                        // length b0 to b1.

    u32 i, term;                                 // index and termination

    f64 tfe, taa, tps;                           // intermediate values for fX and FY

    if (!ob->have_wrist)
        return;

    // calculate travel lengths in fe and aa directions
    // and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lfe = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    laa = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // box xywh
    // current desired  box: fe and aa coordinates as well as width and height
    fe = ob->slot[id].b0.point.x + wrist_i_ref_fn(i, term, 0., 0.1);
    aa = ob->slot[id].b0.point.y + wrist_i_ref_fn(i, term, M_PI / 2.0, 0.1);
    w = ob->slot[id].b0.w + i * lw / term;
    h = ob->slot[id].b0.h + i * lh / term;

    // coordinates of left, right, top, and bottom sides of current desired box
    l = fe - w / 2.0;
    r = fe + w / 2.0;
    b = aa - h / 2.0;
    t = aa + h / 2.0;

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;
    tfe = -ob->wrist.diff_damp * OFE;
    taa = -ob->wrist.diff_damp * OAA;

    // outside
    if (FE < l)
        tfe = -((ob->wrist.diff_stiff * (FE - l)) + (ob->wrist.diff_damp * OFE));
    if (FE > r)
        tfe = -((ob->wrist.diff_stiff * (FE - r)) + (ob->wrist.diff_damp * OFE));
    if (AA < b)
        taa = -((ob->wrist.diff_stiff * (AA - b)) + (ob->wrist.diff_damp * OAA));
    if (AA > t)
        taa = -((ob->wrist.diff_stiff * (AA - t)) + (ob->wrist.diff_damp * OAA));

    // inside
    if (FE > l && FE < r && AA > b && AA < t) {
        // fx = 0.0;
        // fy = 0.0;
        tfe = -ob->wrist.diff_damp * OFE;
        taa = -ob->wrist.diff_damp * OAA;
    }
    // for now, stiffen ps while controlling fe/aa
    tps = ob->wrist.ps_stiff * PS + ob->wrist.ps_damp * OPS;

    TFE = tfe;
    TAA = taa;
    if (!ob->wrist.nocenter3d) {
        TPS = -tps;
    }

    // do not stiffen 2d for now
    wr_slot_term_stiffen_2d(id, 400, 1.0);
    if (!ob->pm.five_d) {
        wr_slot_term_stiffen_ps(id, 400, 2.0);
    }
}

// 1-D moving box controller for wrist ps
void
wrist_ps_ctl(u32 id)
{

    f64 ps, w, h;                                // center fe/aa, width, height
    f64 l, r;                                    // left, right, bottom, top sides of box
    f64 lps, lw, lh;                             // length b0 to b1.

    u32 i, term;                                 // index and termination

    f64 tps;                                     // intermediate value for ps

    if (!ob->have_wrist)
        return;

    // calculate travel lengths in fe and aa directions
    // and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lps = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // box xywh

    // current desired  box: fe and aa coordinates as well as width and height
    ps = ob->slot[id].b0.point.x + i_min_jerk(i, term, lps);
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);

    // coordinates of left, right, top, and bottom sides of current desired box
    l = ps - w / 2.0;
    r = ps + w / 2.0;

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;

    tps = 0.0;
    // outside
    if (PS < l)
        tps = -((ob->wrist.ps_stiff * (PS - l)) + (ob->wrist.ps_damp * OPS));
    if (PS > r)
        tps = -((ob->wrist.ps_stiff * (PS - r)) + (ob->wrist.ps_damp * OPS));

    // inside
    if (PS > l && PS < r) {
        // fx = 0.0;
        // fy = 0.0;
        tps = -ob->wrist.ps_damp * OPS;
    }
    TPS = tps;
    if (!ob->wrist.nocenter3d) {
        // for now, stiffen fe/aa while controlling ps
        TFE = -(ob->wrist.diff_stiff * FE + ob->wrist.diff_damp * OFE);
        TAA = -(ob->wrist.diff_stiff * AA + ob->wrist.diff_damp * OAA);
    }

    wr_slot_term_stiffen_ps(id, 400, 2.0);
    if (!ob->pm.five_d) {
        // do not stiffen 2d for now
        wr_slot_term_stiffen_2d(id, 400, 1.0);
    }
}

// wrist curl controller
// with x=vy y=-vx, and +curl, it rotates cw. -curl rotates ccw.
// with fe=-oaa aa=ofe, and +curl, it rotates cw. -curl rotates ccw.

void
wrist_curl_ctl(u32 id)
{
    f64 curl;
    f64 damp;

    curl = ob->curl;
    damp = ob->wrist.diff_damp;

    TFE = -(-(curl * (OAA)) + (damp * (OFE)));
    TAA = -((curl * (OFE)) + (damp * (OAA)));
    // for now, stiffen ps while controlling fe/aa
    if (!ob->wrist.nocenter3d) {
        TPS = -(ob->wrist.ps_stiff * PS + ob->wrist.ps_damp * OPS);
    }
}

// wrist adaptive controller
// based on the planar adaptive,

// NOTE!  this controller does not follow the "morphing rectangle" paradigm
// of the other controllers.  it takes a starting x/y point and
// a finishing x/y point, and assumes that there is a collapsing slot
// between them.  this is strange and sad, but currently true.
// (this is as in the planar adaptive.)

void
wrist_adap_ctl(u32 id)
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
    box nmov;                                    // the moving box

    f64 left, right, bottom, top;

    xy ftvec;                                    // horizontal ft force vector

    // these are in world space
    xy end;                                      // b1-b0;
    xy off;                                      // offset (-b0)

    xy pos;                                      // pos from encoders
    xy vel;                                      // velocity from encoders
    f64 tps;                                     // output ps value, if we zero it

    // these are space independent
    f64 dwidth;
    f64 w2;
    f64 rot;                                     // angle of rotation
    f64 hyp;                                     // hypotenuse

    u32 i, term;                                 // index and termination
    f64 damp, stiff, side_stiff;

    xy motor_torque;

    xy torque_sen;

    f64 dist_from_target;

    torque_sen.x = ob->wrist.moment_cmd.fe;
    torque_sen.y = ob->wrist.moment_cmd.aa;
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

    damp = ob->wrist.diff_damp;
    stiff = ob->wrist.diff_stiff;

    // if we are going to stiffen, make stiff == side_stiff
    if (ob->slot[id].termi > term) {
        side_stiff = ob->wrist.diff_stiff;
    } else {
        side_stiff = ob->wrist.diff_side_stiff;
    }

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // fx = 0.0;
    // fy = 0.0;

    // normalize manipulandum point/position
    pos.x = FE;
    pos.y = AA;
    off.x = -ob->slot[id].b0.point.x;
    off.y = -ob->slot[id].b0.point.y;
    npos = rotate2d(xlate2d(pos, off), -rot);
    // normalize velocity vector
    vel.x = OFE;
    vel.y = OAA;
    nvel = rotate2d(vel, -rot);
    // normalize ft force
    ftvec.x = torque_sen.x;
    ftvec.y = torque_sen.y;
    nftforce = rotate2d(ftvec, -rot);

    ob->wrist.norm.fe = npos.x;
    ob->wrist.back.fe = nmov.point.x;

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
        ncfvec.y = -((side_stiff * (npos.y - bottom)) + (damp * nvel.y));
    if (npos.y > top)
        ncfvec.y = -((side_stiff * (npos.y - top)) + (damp * nvel.y));

    // inside
    if (npos.x > left && npos.x < right && npos.y > bottom && npos.y < top) {
        ncfvec.x = -damp * nvel.x;
        ncfvec.y = -damp * nvel.y;
    }
    // we have a normal force vector, rotate it back to world space.

    motor_torque = rotate2d(ncfvec, rot);
    TFE = motor_torque.x;
    TAA = motor_torque.y;

    // for now, stiffen ps while controlling fe/aa
    tps = (ob->wrist.ps_stiff * PS + ob->wrist.ps_damp * OPS);
    if (!ob->wrist.nocenter3d) {
        TPS = -tps;
    }
    // do not stiffen 2d for now
    wr_slot_term_stiffen_2d(id, 400, 1.0);

    if (!ob->pm.five_d) {
        wr_slot_term_stiffen_ps(id, 400, 2.0);
    }
    // when 5D, no wrist metrics
    if (ob->pm.five_d) {
        return;
    }
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

    // if the slot times out, freeze the metrics
    // if (i >= term) return;

    if (npos.x > nmov.point.x) {
// diminish this, because it moves quickly
        ob->pm.active_power += 0;
        // this 5.0 is a scaling factor to scale from planar to wrist dimensions
        // empirically derived.
        ob->pm.min_jerk_deviation += fabs(npos.x - nmov.point.x) / 5.0; // pm2b
    } else {
// magnify this, because it moves slowly
        ob->pm.active_power += 10.0 * (nvel.x * nftforce.x);    // pm2a
        ob->pm.robot_power += fabs(nvel.x * nftforce.x);        // pm2a
        ob->pm.min_jerk_deviation += 0;
    }

    // this 5.0 is a scaling factor to scale from planar to wrist dimensions
    // empirically derived.
    ob->pm.min_jerk_dgraph += fabs(npos.x - nmov.point.x) / 5.0;        // pm2b
    ob->pm.jerkmag += ob->wrist.jerkmag;
    ob->pm.dist_straight_line += (npos.y * npos.y);     // pm3

    if (ob->pm.max_dist_along_axis < fabs(npos.x))
        ob->pm.max_dist_along_axis = fabs(npos.x);      // pm4

    if (ob->pm.max_vel < ob->wrist.velmag)
        ob->pm.max_vel = ob->wrist.velmag;

    dist_from_target = fabs(hyp - npos.x);
    if (ob->pm.min_dist_from_target > dist_from_target)
        ob->pm.min_dist_from_target = dist_from_target;

    ob->pm.npoints++;                            // npts
}

#define X PS
#define vX OPS
#define fX TPS

// wrist ps adaptive controller
// derived from linear adaptive
void
wrist_ps_adap_ctl(u32 id)
{

    f64 x, w;
    f64 l, r;                                    // left, right

    u32 i, term;                                 // index and termination
    f64 stiff, damp;

    f64 lx, lw;
    f64 w2;
    f64 back, destx;

    f64 fx;                                      // intermediate values for fX

    f64 torque_sen;

    f64 maxdist;
    f64 dist_from_target;

    torque_sen = ob->wrist.moment_cmd.ps;

    if (!ob->have_wrist)
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

    destx = ob->slot[id].b1.point.x;
    if (fabs(l - destx) > fabs(r - destx)) {
        back = l;
    } else {
        back = r;
    }

    ob->wrist.norm.ps = X;
    ob->wrist.back.ps = back;

    stiff = ob->wrist.ps_stiff;
    damp = ob->wrist.ps_damp;

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

    if (!ob->wrist.nocenter3d) {
        // for now, stiffen fe/aa while controlling ps
        TFE = -(ob->wrist.diff_stiff * FE + ob->wrist.diff_damp * OFE);
        TAA = -(ob->wrist.diff_stiff * AA + ob->wrist.diff_damp * OAA);
    }
    // when 5D, no wrist metrics
    if (ob->pm.five_d) {
        return;
    }

    wr_slot_term_stiffen_ps(id, 400, 2.0);

    if (!ob->pm.five_d) {
	// do not stiffen 2d for now
        wr_slot_term_stiffen_2d(id, 400, 1.0);
    }
    // performance metrics

    // is this slot going up (+x) or down (-x)
    ob->wrist.ps_adap_going_up = 1;
    if (lx < 0.0) {
        ob->wrist.ps_adap_going_up = 0;
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

    // if the slot times out, freeze the metrics
    // if (i >= term) return;

    if (ob->wrist.ps_adap_going_up) {
        if (X > back) {
            ob->pm.active_power += 0;
            ob->pm.robot_power += 0;
            ob->pm.min_jerk_deviation += fabs(X - back) / 10.0; // pm2b
        } else {
            ob->pm.active_power += (vX * torque_sen) * 5.0;     // pm2a
            ob->pm.robot_power += fabs(vX * torque_sen);
            ob->pm.min_jerk_deviation += 0;
        }
        if (ob->slot[id].b1.point.x == 0.0) {
            maxdist = ob->slot[id].b0.w + X;
        } else {
            maxdist = X;
        }
    } else {
        if (X < back) {
            ob->pm.active_power += 0;
            ob->pm.robot_power += 0;
            ob->pm.min_jerk_deviation += fabs(X - back) / 10.0; // pm2b
        } else {
            ob->pm.active_power += (vX * torque_sen) * 5.0;     // pm2a
            ob->pm.robot_power += fabs(vX * torque_sen);
            ob->pm.min_jerk_deviation += 0;
        }
        if (ob->slot[id].b1.point.x == 0.0) {
            maxdist = ob->slot[id].b0.w - X;
        } else {
            maxdist = -X;
        }
    }

    dist_from_target = fabs(destx - X);

    if (ob->pm.max_dist_along_axis < maxdist)
        ob->pm.max_dist_along_axis = maxdist;

    if (ob->pm.min_dist_from_target > dist_from_target)
        ob->pm.min_dist_from_target = dist_from_target;

    ob->pm.min_jerk_dgraph += fabs(X - back) * 2.0;     // pm2b

    ob->pm.jerkmag += fabs(ob->wrist.jerk.ps);

    ob->pm.dist_straight_line = 0.0;
    ob->pm.npoints++;                            // npts
}

void
wrist_ref_ctl(u32 id)
{

    f64 stiff, damp;

    stiff = ob->wrist.diff_stiff;
    damp = ob->wrist.diff_damp;

    TFE = -((stiff * (FE - ob->wrist.ref_pos.fe)) + (damp * OFE));
    TAA = -((stiff * (AA - ob->wrist.ref_pos.aa)) + (damp * OAA));
    TPS = -(ob->wrist.ps_stiff * PS + ob->wrist.ps_damp * OPS);
}

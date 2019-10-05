// an_uslot.c - ankle robot user slot functions,
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

//Define position, velocity and torque parameters in world coordinates.
//In this function, uppercase (lowercase) letters refer to actual (desired) parameters.
//
// dorsiflexion/plantarflexion
#define DP ob->ankle.pos.dp
#define ODP ob->ankle.fvel.dp
#define TDP ob->ankle.torque.dp

// inversion/eversion
#define IE ob->ankle.pos.ie
#define OIE ob->ankle.fvel.ie
#define TIE ob->ankle.torque.ie

// 2-D moving box controller for ankle
void
ankle_ctl(u32 id)
{

    f64 dp, ie, w, h;
    f64 l, r, b, t;                              // left, right, bottom, top

    u32 i, term;                                 // index and termination
    f64 stiff, damp;

    f64 ldp, lie, lw, lh;
    f64 w2, h2;

    f64 tdp, tie;                                // intermediate values for fX and FY

    if (!ob->have_ankle)
        return;

    // calculate travel lengths in fe and aa directions and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lie = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    ldp = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0)
        term = 1;
    i = ob->slot[id].i;

    // current desired  box: ie and dp coordinates as well as width and height
    ie = ob->slot[id].b0.point.x + i * lie / term;
    dp = ob->slot[id].b0.point.y + i * ldp / term;
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i * lw / term;
    ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i * lh / term;


    // coordinates of left, right, top, and bottom sides of current desired box
    // done??

    // wall lrtb
    w2 = w / 2.0;
    h2 = h / 2.0;
    l = ie - w2;
    r = ie + w2;
    b = dp - h2;
    t = dp + h2;

    stiff = ob->ankle.stiff;
    damp = ob->ankle.damp;

    // in case nothing triggers, should not happen.

    // use -damp*V as the "zero" force, or you will feel
    // a bump when you "hit the wall of the box."

    // was...
    // tie = 0.0;
    // tdp = 0.0;
    tie = -damp * OIE;
    tdp = -damp * ODP;

    // outside
    if (IE < l)
        tie = -((stiff * (IE - l)) + (damp * OIE));
    if (IE > r)
        tie = -((stiff * (IE - r)) + (damp * OIE));
    if (DP < b)
        tdp = -((stiff * (DP - b)) + (damp * ODP));
    if (DP > t)
        tdp = -((stiff * (DP - t)) + (damp * ODP));

    // inside
    if (IE > l && IE < r && DP > b && DP < t) {
        // tie = 0.0;
        // tdp = 0.0;
        tie = -damp * OIE;
        tdp = -damp * ODP;
    }
    TIE = tie;
    TDP = tdp;

    // this stiffens the planar for now...
    // slot_term_stiffen(id, 400, 3.0);
}

void
ankle_point_ctl(u32 id)
{

    f64 stiff, damp;

    stiff = ob->ankle.stiff;
    damp = ob->ankle.damp;

    TDP = -((stiff * (DP - ob->ankle.ref_pos.dp)) + (damp * ODP));
    TIE = -((stiff * (IE - ob->ankle.ref_pos.ie)) + (damp * OIE));
}

// 2-D moving box controller for pediatric anklebot wit PM2
// modified (from anle_ctl and adap_ctl) and augmented by Konstantinos P. Michmizos (konmic@mit.edu)
void
ankle_Fitts_ctl(u32 id)
{

    f64 dp, ie, w, h;
    f64 l, r, b, t;             // left, right, bottom, top

    u32 i, term;	// index and termination
    f64 stiff, damp;

    f64 ldp, lie, lw, lh;
    f64 w2, h2;

    f64 tdp, tie;		// intermediate values for fX and FY

    f64 mj_ie, mj_dp;  // added by Konstantinos Michmizos (min jerk ie/dp)
    f64 bw_ie, bw_dp; // added by Konstantinos Michmizos (back wall) 
	
    f64 torque_ie, torque_dp; // added by Konstantinos Michmizos (torque i/dp)
   
    if (!ob->have_ankle) return;

    // calculate travel lengths in fe and aa directions and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lie = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    ldp = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0) term = 1;
    i = ob->slot[id].i;

    // current desired  box: ie and dp coordinates as well as width and height
    // uncomment these 4 lines (and comment the next 4 lines) to get a linearly collapsing bw
    //ie = ob->slot[id].b0.point.x + i * lie / term;
    //dp = ob->slot[id].b0.point.y + i * ldp / term;
    //ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i * lw / term;
    //ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i * lh / term;

    mj_ie = i_min_jerk(i, term, lie);
    ie = ob->slot[id].b0.point.x + mj_ie; 
    mj_dp = i_min_jerk(i, term, ldp);
    dp = ob->slot[id].b0.point.y + mj_dp;
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);
    ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i_min_jerk(i, term, lh);

    // coordinates of left, right, top, and bottom sides of current desired box

    // wall lrtb
    w2 = w / 2.0;
    h2 = h / 2.0;
    l = ie - w2;
    r = ie + w2;
    b = dp - h2;
    t = dp + h2;


    // performance metrics
// pm2a: sum of power along target axis
// pm2b: sum of deviation from min. jerk pos
// npts: number of points in the above sums
// note that these pm.things are all state, except for npoints
// npoints must be zeroed to init, the rest need not be zeroed.

	//torque_ie = ob->ankle.moment_cmd.ie;
	//torque_dp = ob->ankle.moment_cmd.dp;

	// we need to replace these with the force transducers' variables.
	torque_ie = ob->ankle.torque.ie;
	torque_dp = ob->ankle.torque.dp;

	if (lie>0) {
		// bw_ie = ob->slot[id].b0.point.x - fabs(ob->slot[id].b0.w/2.0)  + mj_ie;
		bw_ie =  l;
	} else {
		// bw_ie = ob->slot[id].b0.point.x + fabs(ob->slot[id].b0.w/2.0) - mj_ie;
		bw_ie = r;
	}

	if (ldp>0) {
		// bw_dp = ob->slot[id].b0.point.y - fabs(ob->slot[id].b0.h/2.0)  + mj_dp;
		bw_dp = b;
	} else {
		// bw_dp = ob->slot[id].b0.point.y + fabs(ob->slot[id].b0.h/2.0) - mj_dp;
		bw_dp = t;
	}

	// first we check the type of motion (ie/dp)
	// then we check whether we go right (up) or left (down)
	// we calculate metrics with respect to the back wall (bw_ie, bw_dp)
	if (ob->slot[id].b1.point.y == 0.0) {
		if (lie>0) {
    			if (IE > bw_ie) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += (IE - bw_ie); // pm2b
    			} else {
				ob->pm.active_power += (OIE * torque_ie);       // pm2a
				ob->pm.min_jerk_deviation += (IE - bw_ie);
    			}
	        	ob->pm.min_jerk_dgraph += (IE - bw_ie); // graph
		} else {
    			if (IE < bw_ie) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += (-IE + bw_ie); // pm2b
    			} else {
				ob->pm.active_power += (OIE * torque_ie);       // pm2a
				ob->pm.min_jerk_deviation += (-IE + bw_ie);
    			}
	        	ob->pm.min_jerk_dgraph += fabs(IE - bw_ie); // graph
		}
	} else {
		if (ldp>0) {
			if (DP > bw_dp) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += (DP - bw_dp); // pm2b
    			} else {
				ob->pm.active_power += (ODP * torque_dp);       // pm2a
				ob->pm.min_jerk_deviation += (DP - bw_dp);
    			}
    			ob->pm.min_jerk_dgraph += fabs(DP - bw_dp); // graph
		} else {
			if (DP < bw_dp) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += (-DP + bw_dp); // pm2b
    			} else {
				ob->pm.active_power += (ODP * torque_dp);       // pm2a
				ob->pm.min_jerk_deviation += (-DP + bw_dp);
    			}
    			ob->pm.min_jerk_dgraph += fabs(DP - bw_dp); // graph
		}
	}

    ob->pm.npoints++; // npts

    stiff = ob->ankle.stiff;
    damp = ob->ankle.damp;

    tie = -damp * OIE;
    tdp = -damp * ODP;

    // outside
    if (IE < l)
        tie = -((stiff * (IE - l)) + (damp * OIE));
    if (IE > r)
        tie = -((stiff * (IE - r)) + (damp * OIE));
    if (DP < b)
        tdp = -((stiff * (DP - b)) + (damp * ODP));
    if (DP > t)
        tdp = -((stiff * (DP - t)) + (damp * ODP));

    // inside
    if (IE > l && IE < r && DP > b && DP < t) {
        //tie = 0.0;
        //tdp = 0.0;
        tie = -damp * OIE;
        tdp = -damp * ODP;
    }
    TIE = tie;
    TDP = tdp;

    // this stiffens the planar for now...
    // slot_term_stiffen(id, 400, 3.0);
}



// 2-D moving box controller for pediatric anklebot wit PM2
// modified (from anle_ctl and adap_ctl) and augmented by Konstantinos P. Michmizos (konmic@mit.edu)
void
ankle_ped_ctl(u32 id)
{

    f64 dp, ie, w, h;
    f64 l, r, b, t;             // left, right, bottom, top

    u32 i, term;	// index and termination
    f64 stiff, damp;

    f64 ldp, lie, lw, lh;
    f64 w2, h2;

    f64 tdp, tie;		// intermediate values for fX and FY

    f64 mj_ie, mj_dp;  // added by Konstantinos Michmizos (min jerk ie/dp)
    f64 bw_ie, bw_dp; // added by Konstantinos Michmizos (back wall) 
	
    f64 torque_ie, torque_dp; // added by Konstantinos Michmizos (torque i/dp)
   
    if (!ob->have_ankle) return;

    // calculate travel lengths in fe and aa directions and intermediate box dimension parameters
    // (x corresponds to fe and y corresponds to aa)
    lie = ob->slot[id].b1.point.x - ob->slot[id].b0.point.x;
    ldp = ob->slot[id].b1.point.y - ob->slot[id].b0.point.y;
    lw = ob->slot[id].b1.w - ob->slot[id].b0.w;
    lh = ob->slot[id].b1.h - ob->slot[id].b0.h;

    // time management
    term = ob->slot[id].term;
    if (term == 0) term = 1;
    i = ob->slot[id].i;

    // current desired  box: ie and dp coordinates as well as width and height
    // uncomment these 4 lines (and comment the next 4 lines) to get a linearly collapsing bw  
    //ie = ob->slot[id].b0.point.x + i * lie / term;
    //dp = ob->slot[id].b0.point.y + i * ldp / term;
    //ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i * lw / term;
    //ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i * lh / term;

    mj_ie = i_min_jerk(i, term, lie);
    ie = ob->slot[id].b0.point.x + mj_ie; 
    mj_dp = i_min_jerk(i, term, ldp);
    dp = ob->slot[id].b0.point.y + mj_dp;
    ob->slot[id].bcur.w = w = ob->slot[id].b0.w + i_min_jerk(i, term, lw);
    ob->slot[id].bcur.h = h = ob->slot[id].b0.h + i_min_jerk(i, term, lh);

    // coordinates of left, right, top, and bottom sides of current desired box

    // wall lrtb
    w2 = w / 2.0;
    h2 = h / 2.0;
    l = ie - w2;
    r = ie + w2;
    b = dp - h2;
    t = dp + h2;


    	// performance metrics
	// pm2a: sum of power along target axis
	// pm2b: sum of deviation from min. jerk pos
	// npts: number of points in the above sums
	// note that these pm.things are all state, except for npoints
	// npoints must be zeroed to init, the rest need not be zeroed.

	//torque_ie = ob->ankle.moment_cmd.ie;
	//torque_dp = ob->ankle.moment_cmd.dp;

	// we need to replace these with the force transducers' variables.
	torque_ie = ob->ankle.torque.ie;
	torque_dp = ob->ankle.torque.dp;

	if (lie>0) {
		// bw_ie = ob->slot[id].b0.point.x - fabs(ob->slot[id].b0.w/2.0)  + mj_ie;
		bw_ie =  l;
	} else {
		// bw_ie = ob->slot[id].b0.point.x + fabs(ob->slot[id].b0.w/2.0) - mj_ie;
		bw_ie = r;
	}

	if (ldp>0) {
		// bw_dp = ob->slot[id].b0.point.y - fabs(ob->slot[id].b0.h/2.0)  + mj_dp;
		bw_dp = b;
	} else {
		// bw_dp = ob->slot[id].b0.point.y + fabs(ob->slot[id].b0.h/2.0) - mj_dp;
		bw_dp = t;
	}

	// first we check the type of motion (ie/dp)
	// then we check whether we go right (up) or left (down)
	// we calculate metrics with respect to the back wall (bw_ie, bw_dp)
	if (ob->slot[id].b1.point.y == 0.0) {
		if (lie>0) {
    			if (IE > bw_ie) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += fabs(IE - bw_ie); // pm2b
    			} else {
				ob->pm.active_power += (OIE * torque_ie);       // pm2a
				ob->pm.min_jerk_deviation += 0;
    			}
	        	ob->pm.min_jerk_dgraph += fabs(IE - bw_ie); // graph
		} else {
    			if (IE < bw_ie) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += fabs(IE - bw_ie); // pm2b
    			} else {
				ob->pm.active_power += (OIE * torque_ie);       // pm2a
				ob->pm.min_jerk_deviation += 0;
    			}
	        	ob->pm.min_jerk_dgraph += fabs(IE - bw_ie); // graph
		}
	} else {
		if (ldp>0) {
			if (DP > bw_dp) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += fabs(DP - bw_dp); // pm2b
    			} else {
				ob->pm.active_power += (ODP * torque_dp);       // pm2a
				ob->pm.min_jerk_deviation += 0;
    			}
    			ob->pm.min_jerk_dgraph += fabs(DP - bw_dp); // graph
		} else {
			if (DP < bw_dp) {
				ob->pm.active_power += 0;
				ob->pm.min_jerk_deviation += fabs(DP - bw_dp); // pm2b
    			} else {
				ob->pm.active_power += (ODP * torque_dp);       // pm2a
				ob->pm.min_jerk_deviation += 0;
    			}
    			ob->pm.min_jerk_dgraph += fabs(DP - bw_dp); // graph
		}
	}

    ob->pm.npoints++; // npts

    stiff = ob->ankle.stiff;
    damp = ob->ankle.damp;

    tie = -damp * OIE;
    tdp = -damp * ODP;

    // outside
    if (IE < l)
        tie = -((stiff * (IE - l)) + (damp * OIE));
    if (IE > r)
        tie = -((stiff * (IE - r)) + (damp * OIE));
    if (DP < b)
        tdp = -((stiff * (DP - b)) + (damp * ODP));
    if (DP > t)
        tdp = -((stiff * (DP - t)) + (damp * ODP));

    // inside
    if (IE > l && IE < r && DP > b && DP < t) {
        //tie = 0.0;
        //tdp = 0.0;
        tie = -damp * OIE;
        tdp = -damp * ODP;
    }
    TIE = tie;
    TDP = tdp;

    // this stiffens the planar for now...
    // slot_term_stiffen(id, 400, 3.0);
}

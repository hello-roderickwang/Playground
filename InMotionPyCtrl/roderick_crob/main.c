// main.c - InMotion2 main loop
// part of the robot.o robot process

// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include "rtl_inc.h"

RT_TASK thread;
RT_TASK_INFO thread_info;

#include "ruser.h"
#include "robdecls.h"

#include "userfn.h"

// Xenomai has 1 ns resolution.  Multipliers: seconds 10^0,
// millisecond 10^-3, microsecond 10^-6, nanoseconds 10^-9.

// sample tick 200 Hz, or 5 ms or 5,000,000 ns.

// tick rate can be reset with ob->restart.Hz and restart_init();

#define STACK_SIZE 8192
#define STD_PRIO 1

// ob storage definition
// the ob structure contains globals

int ob_shmid;
int rob_shmid;
int daq_shmid;
int prev_shmid;
int refbuf_shmid;

Ob *ob;
Robot *rob;
Daq *daq;
Prev *prev;
Refbuf *refbuf;

void
cleanup_devices()
{
    // shut down devices here.
    can_close();
    uei_aio_close();
    pci4e_close();

}

/// cleanup_signal - start the cleanup at the next tick.

void
cleanup_signal(s32 sig)
{
    s32 ret;

    write_zero_torque();
    ob->paused = 1;
    ob->quit = 1;
}

void
do_cleanup(s32 sig)
{
    s32 ret;

    write_zero_torque();
    ret = rt_task_set_periodic(NULL, TM_NOW, TM_INFINITE);

    cleanup_devices();
    cleanup_fifos();

    shmdt(ob);
    shmdt(rob);
    shmdt(daq);
    shmdt(prev);
    shmdt(refbuf);

    shmctl(ob_shmid, IPC_RMID, NULL);
    shmctl(rob_shmid, IPC_RMID, NULL);
    shmctl(daq_shmid, IPC_RMID, NULL);
    shmctl(prev_shmid, IPC_RMID, NULL);
    shmctl(refbuf_shmid, IPC_RMID, NULL);

    rob_log("Stopping robot realtime process.\n");
    closelog();

    ret = rt_task_inquire(NULL, &thread_info);
    if (!strcmp(thread_info.name, ROBOT_LOOP_THREAD_NAME)) {
        // Exit if we are the child
        exit(0);
    }
}

// looks like printf, sends stuff to LOG_INFO
void
rob_log(const char *fmt, ...)
{
    const int max_string_length = 4096;
    char tmp[max_string_length];
    va_list args;
    va_start(args, fmt);
    vsnprintf(tmp, max_string_length, fmt, args);
    va_end(args);
    syslog(LOG_INFO, "%s", tmp);
}




/// main -
///
/// inits some variables
/// enables floating point
/// and creates thread with start_routine.

s32
main(void)
{
    printf("This is main function in main.c\n")
    s32 ret;
    pthread_attr_t attr;

    if (!getenv("NO_ROBOT_DAEMON"))
	daemon(0, 0);

    openlog("imt-robot", LOG_PID, LOG_USER);
    setlogmask(LOG_UPTO(LOG_INFO));
    rob_log("Starting robot realtime process.\n");

    // for rt_printf
    rt_print_auto_init(1);

    // init some variables
    main_init();

    // install signal handler
    ret = (s32) signal(SIGTERM, cleanup_signal);
    if (ret == (s32) SIG_ERR) {
        rob_log("%s:%d %s, signal() returned SIG_ERR\n", __FILE__, __LINE__, __FUNCTION__);
    }
    ret = (s32) signal(SIGINT, cleanup_signal);
    if (ret == (s32) SIG_ERR) {
        rob_log("%s:%d %s, signal() returned SIG_ERR\n", __FILE__, __LINE__, __FUNCTION__);
    }
    ret = (s32) signal(SIGHUP, cleanup_signal);
    if (ret == (s32) SIG_ERR) {
        rob_log("%s:%d %s, signal() returned SIG_ERR\n", __FILE__, __LINE__, __FUNCTION__);
    }

    setsid();

    ret = pthread_attr_init(&attr);
    ret = pthread_attr_setstacksize(&attr, 64*1024);

    mlockall(MCL_CURRENT | MCL_FUTURE);

    {
        // No one handles any signals for now, will be inherited by child.
        sigset_t signalSet;

        sigfillset(&signalSet);
        pthread_sigmask(SIG_BLOCK, &signalSet, NULL);
    }

    ret =
        rt_task_spawn(&thread, ROBOT_LOOP_THREAD_NAME, STACK_SIZE, STD_PRIO, 0,
                      &start_routine, NULL);

    {
	// Now that child is spawned, set signals so we will get them.
        sigset_t signalSet;

        sigemptyset(&signalSet);
        sigaddset(&signalSet, SIGTERM);
        sigaddset(&signalSet, SIGINT);
        sigaddset(&signalSet, SIGHUP);
        pthread_sigmask(SIG_UNBLOCK, &signalSet, NULL);
    }

    pause();

    // fflush(NULL);  // TODO: move to someplace where this executes

    return 0;
}

// adjust the tick rate, called by start_routine and restart_init
// last reworked tick code 5/2007

void
set_Hz()
{
    if (ob->Hz <= 0)
        ob->Hz = 1;

    // nanoseconds
    ob->irate = 1000 * 1000 * 1000 / ob->Hz;     // 5,000,000 for 200 Hz
    ob->rate = 1.0 / ob->Hz;                     // 0.005
}

/// start_routine - the thread starts here
///
/// this is the thread entry point set up by pthread_create.
/// it invokes the main loop, which is run ob->Hz times per second.

void
start_routine(void *arg)
{
    s32 ret;

    set_Hz();

    ob->main_thread = thread;

    // start timer
    // now happens automatically
    // ret = rt_timer_start(TM_ONESHOT);

    ret = rt_task_set_periodic(NULL, TM_NOW, ob->irate);

    wait_for_tick();
    wait_for_tick();
    main_loop();
}

/// main_init - do this stuff once, before running main_loop
///
/// init some variables.

void
main_init(void)
{
    hrtime_t t, h1, h2;

    ob_shmid = shmget(OB_KEY, sizeof(Ob), IPC_CREAT | 0666);
    if (ob_shmid == -1) {
        rob_log("%s:%d %s, ob_shmid is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    rob_shmid = shmget(ROB_KEY, sizeof(Robot), IPC_CREAT | 0666);
    if (rob_shmid == -1) {
        rob_log("%s:%d %s, rob_shmid is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    daq_shmid = shmget(DAQ_KEY, sizeof(Daq), IPC_CREAT | 0666);
    if (daq_shmid == -1) {
        rob_log("%s:%d %s, daq_shmid is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    prev_shmid = shmget(PREV_KEY, sizeof(Prev), IPC_CREAT | 0666);
    if (prev_shmid == -1) {
        rob_log("%s:%d %s, prev_shmid is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    refbuf_shmid = shmget(REFBUF_KEY, sizeof(Refbuf), IPC_CREAT | 0666);
    if (refbuf_shmid == -1) {
        rob_log("%s:%d %s, refbuf_shmid is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }

    ob = shmat(ob_shmid, NULL, 0);
    if ((s32) ob == -1) {
        rob_log("%s:%d %s, ob is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    rob = shmat(rob_shmid, NULL, 0);
    if ((s32) rob == -1) {
        rob_log("%s:%d %s, rob is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    daq = shmat(daq_shmid, NULL, 0);
    if ((s32) daq == -1) {
        rob_log("%s:%d %s, daq is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    prev = shmat(prev_shmid, NULL, 0);
    if ((s32) prev == -1) {
        rob_log("%s:%d %s, prev is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }
    refbuf = shmat(refbuf_shmid, NULL, 0);
    if ((s32) refbuf == -1) {
        rob_log("%s:%d %s, refbuf is -1, errno == %d\n", __FILE__, __LINE__, __FUNCTION__, errno);
        do_cleanup(0);
    }

    memset(ob, 0, sizeof(Ob));
    memset(rob, 0, sizeof(Robot));
    memset(daq, 0, sizeof(Daq));
    memset(prev, 0, sizeof(Prev));
    memset(refbuf, 0, sizeof(Refbuf));

    uei_ptr_init();

    // set up some daq-> pointers

    ob->paused = 1;
    ob->last_shm_val = 12345678;
    ob->i = 0;
    ob->samplenum = 0;
    ob->total_samples = 0;
    ob->busy = 0;

    ob->Hz = 200;

    ob->fifolen = FIFOLEN;
    ob->nlog = 0;
    ob->ndisp = 0;

    ob->stiff = 100.0;
    ob->damp = 5.0;
    ob->pfomax = 10.0;
    ob->pfotest = 10.0;

    ob->friction = 0.1;
    ob->friction_gap = 0.002;

    ob->planar_uei_ao_board_handle = 1;

    rob->shoulder.angle.channel = 1;
    rob->shoulder.torque.channel = 1;
    rob->shoulder.vel.channel = 1;

    rob->elbow.angle.channel = 0;
    rob->elbow.torque.channel = 0;
    rob->elbow.vel.channel = 0;

    rob->shoulder.angle.offset = -4.93069;
    rob->shoulder.angle.xform = 0.00009587;
    rob->shoulder.torque.offset = 0.0;
    rob->shoulder.torque.xform = 5.6;
    rob->shoulder.vel.offset = -0.0230;
    rob->shoulder.vel.xform = 1.0;

    rob->elbow.angle.offset = 1.29309;
    rob->elbow.angle.xform = 0.00009587;
    rob->elbow.torque.offset = 0.0;
    rob->elbow.torque.xform = -5.8;
    rob->elbow.vel.offset = 0.0230;
    rob->elbow.vel.xform = -1.0;

    rob->offset.x = 0;
    rob->offset.y = -0.65;

    wrist_init();
    ankle_init();
    //    linear_init();
    hand_init();

    // force transducer params
    rob->ft.offset = 0.0;                        // radians
    rob->link.s = 0.4064;                        // meters ~= .4 m
    rob->link.e = 0.51435;                       // meters ~= .5 m

    // safety envelope
    ob->safety.pos = 0.2;
    ob->safety.vel = 2.0;
    ob->safety.torque = 80.0;

    // safety damping Nm/s
    ob->safety.damping_nms = 35.0;

    ob->safety.velmag_kick = 5.0;

    init_fifos();

    t = rt_timer_tsc2ns(rt_timer_tsc());
    ob->times.time_before_last_sample = t;
    ob->times.time_after_last_sample = t;
    ob->times.time_after_sample = t;
    ob->times.time_before_sample = t;
    ob->times.time_at_start = t;
    ob->times.time_since_start = 0;
    ob->times.ms_since_start = 0;
    ob->times.sec = 0;

    // jitter thresholds
    ob->times.ns_delta_tick_thresh = 120;        // % of irate
    // sample thresh used to be 10% because the tick should only take about 3% of the cpu
    // but now we wait for the can response, so it takes about 25%, though most of it is waiting.
    ob->times.ns_delta_sample_thresh = 40;       // % of irate

    h1 = rt_timer_tsc();
    h2 = rt_timer_tsc();
    ob->times.time_delta_call = rt_timer_tsc2ns(h2 - h1);
    ob->times.ns_delta_call = (u32) ob->times.time_delta_call;

    // make sure trig works.
    ob->pi = 4.0 * atan(1.0);

    docarr();
}

// do init after calibration file is read
// for stuff like starting boards.

void
do_init(void)
{
    user_init();
    sensact_init();

    can_init();
    uei_aio_init();
    pci4e_init();

    if (ob->have_can) {
	can_init_bitmask();
	can_set_heartbeat(CAN_HEARTBEAT_ENABLE);
    }

    ob->didinit = 1;
    ob->doinit = 0;
}

// we get here because ob->restart.go was set.
// I hope we are paused...
// Hz may have changed, so rate must be set as well.
//
void
restart_init(void)
{
    hrtime_t t;

    if (ob->restart.Hz < 1) {
        ob->restart.go = 0;
        return;
    }

    t = rt_timer_tsc2ns(rt_timer_tsc());
    ob->times.time_before_last_sample = t;
    ob->times.time_after_last_sample = t;
    ob->times.time_after_sample = t;
    ob->times.time_before_sample = t;
    ob->times.time_at_start = t;
    ob->times.time_since_start = 0;
    ob->times.ms_since_start = 0;
    ob->times.sec = 0;

    // ob->stiff = ob->restart.stiff;
    // ob->damp = ob->restart.damp;

    ob->i = 0;
    ob->samplenum = 0;

    // adjust actual timer
    ob->Hz = ob->restart.Hz;

    set_Hz();

    rt_task_set_periodic(NULL, TM_NOW, ob->irate);
    ob->restart.go = 0;
}

// this needs to happen all at once between samples.

void
shm_copy_commands(void)
{
    // restart will start cleanly.
    if (ob->restart.go) {
        can_set_heartbeat(CAN_HEARTBEAT_DISABLE);
        restart_init();
        can_set_heartbeat(CAN_HEARTBEAT_ENABLE);
    }
    // if there's a new slot command, copy it in.
    if (ob->copy_slot.go) {
        ob->slot[ob->copy_slot.id] = ob->copy_slot;
        memset(&ob->copy_slot, 0, sizeof(Slot));
        ob->copy_slot.go = 0;                    // for good measure
    }
    if (rob->pci4e.zero) {
	    pci4e_reset_all_ctrs();
	    rob->pci4e.zero = 0;
    }
    if (rob->pci4e.dosetct) {
	    pci4e_set_all_ctrs();
	    rob->pci4e.dosetct = 0;
    }
    if (rob->ft.dobias) {
	    ft_zero_bias();
	    rob->ft.dobias = 0;
    }
    if (ob->ref_switchback_go) {
        refarr_switchback();
        ob->ref_switchback_go = 0;
    }
}

/// one 200Hz sample - this is where the action is.
/// this is where the actuators are written
/// and the logging is done.
///
/// the work that happens here is:
/// check exit conditions (late and quit)
/// read sensors
/// read references
/// compute control outputs
/// check safety
/// write actuators
/// write log data
/// wait for next tick
///
/// if ob->paused is set, sampling is done,
/// but no actuators are written.

static void
one_sample(void)
{
// if (!(ob->i % 200))rob_log("o %d", ob->i);
    printf("This is in one_sample function.\n")
    do_time_before_sample();

    shm_copy_commands();

    if (ob->doinit && !ob->didinit) {
        do_init();
    }
    check_late();

    // do all this stuff even when we're paused,
    // so that filters are properly primed when we unpause
    read_sensors();
    read_reference();
    compute_controls();
    check_safety();

    if (!ob->paused) {
        // only write stuff (including motor forces) when not paused
        if (!ob->test_no_torque) {               // for goofy tests without a robot hooked up
            write_actuators();
        }
        write_log();
        ob->samplenum++;

    } else {
        // zero douts, might be leds, etc
        // this really happens in read_sensors above.
        daq->dout0 = 0;
        daq->dout1 = 0;
        // send zeros to motors on every paused cycle.
        stop_all_slots();
        write_zero_torque();
    }

    if (ob->have_can) {
	// timeout is 1.25 * interval.  interval is 100 ms.
	// convert to ticks (20 if 200Hz)
	if ((ob->i % (ob->Hz * CAN_HEARTBEAT_INTERVAL_MS / 1000)) == 0) {
	    can_send_heartbeat();
	}
    }

    do_time_after_sample();

    // put a newline to tcfifo every ntickfifo samples.
    // you read from this tick fifo as a sample timer in user space.
    // this is telling the user to wake up, so do it *right* before
    // the control loop goes to sleep, when *all* the variables
    // (even do_time_after_sample) are written.
    if (ob->ntickfifo && ((ob->i % ob->ntickfifo) == 0)) {
        rt_pipe_write(&(ob->tcfifo), "\n", 1, P_NORMAL);
    }
    // write to the ft fifo to trigger atinetft
    if (ob->fttickfifo) {
        rt_pipe_write(&(ob->ftfifo), "\n", 1, P_NORMAL);
    }

    ob->busy = 0;
    wait_for_tick();
    ob->i++;
}

void
main_loop(void)
{
    // ticking at 1000 Hz, ob->i (31 bits) will overflow in
    // (2^31)/(1000*60*60*24) == 24.85 days.
    for (;;) {
        if (!ob->quit) {
	    one_sample();
        } else {
	    if (ob->have_can)
		can_set_heartbeat(CAN_HEARTBEAT_DISABLE);  // stop the heartbeat monitoring
            do_cleanup(0);
	}
    }
}

/// do_time_before_sample - do housekeeping before sample

void
do_time_before_sample()
{

    ob->times.time_before_last_sample = ob->times.time_before_sample;
    ob->times.time_before_sample = rt_timer_tsc2ns(rt_timer_tsc());
    ob->times.time_delta_tick =
        ob->times.time_before_sample - ob->times.time_before_last_sample;
    ob->times.time_since_start = ob->times.time_before_sample - ob->times.time_at_start;

    ob->times.ms_since_start = (u32) (ob->times.time_since_start / 1000000);
    ob->times.sec = ob->times.ms_since_start / 1000;
    ob->times.ns_delta_tick = (u32) ob->times.time_delta_tick;

    if (ob->times.ns_max_delta_tick < ob->times.ns_delta_tick)
        ob->times.ns_max_delta_tick = ob->times.ns_delta_tick;

    ob->times.time_before_send_sync = ob->times.time_before_sample;
}

// add an error code to the rolling ob->error
void
do_error(u32 code)
{
    u32 mod, ai;

    // early errors are spurious.
    if (ob->i < 10)
        return;

    mod = ARRAY_SIZE(ob->errori);
    ob->errorindex = ai = ob->nerrors % mod;
    ob->errori[ai] = ob->i;
    ob->errorcode[ai] = code;
    ob->nerrors++;
}

// report to the error-reporting daemon
void
notify_error(char *action, char *message)
{
    char line [4096];
    int size = sprintf(line, "action=%s;message=%s\n", action, message);

    rob_log(line);
    rt_pipe_write(&(ob->eofifo), line, size, P_NORMAL);
}



/// check_late - see if the sample has taken longer than expected.

void
check_late()
{
    // is busy still set?
    if (ob->busy != 0 && ob->i > 10) {
        do_error(ERR_MAIN_LATE_TICK);
    }
    // is the tick too slow, i.e., if the thresh is 120 for a 200Hz (5ms) tick,
    // did the tick take > 6ms?
    if (ob->times.ns_delta_tick > (ob->times.ns_delta_tick_thresh * ob->irate / 100)) {
        do_error(WARN_MAIN_SLOW_TICK);
    }
    // is the tick too fast, i.e., if the thresh is 120 for a 200Hz (5ms) tick,
    // did the tick take < 4ms?
    if (ob->times.ns_delta_tick <
        ((100 - (ob->times.ns_delta_tick_thresh - 100)) * ob->irate / 100)) {
        do_error(WARN_MAIN_FAST_TICK);
    }

    // we increment it here.  if it ever gets to be >1,
    // something is really wrong.
    ob->busy++;
}

// no longer called by main loop, since we call read_sensors even
// when we are paused.

/// clear_sensors - read the sensors a few times, to clear them.
// read_sensors and compute_controls must both be called
// to prime filters.
// zero torques too, can't hurt.
// periodic thread must already exist.
//
void
clear_sensors()
{
    s32 i;

    for (i = 0; i < 20; i++) {
        do_time_before_sample();
        read_sensors();
        compute_controls();
        write_zero_torque();
        do_time_after_sample();
        wait_for_tick();
        ob->i++;
    }
    ob->samplenum = 0;
    ob->times.ns_max_delta_tick = 0;
    ob->times.ns_max_delta_sample = 0;
}

// sets the torque variables to zero
//
void
set_zero_torque(void)
{
    if (ob->have_planar)
        planar_set_zero_torque();
    if (ob->have_wrist)
        wrist_set_zero_torque();
    if (ob->have_ankle)
        ankle_set_zero_torque();
    //    if (ob->have_linear)
    //        linear_set_zero_force();
    if (ob->have_hand)
        hand_set_zero_force();
}

// writes zeros to the a/d boards
//
void
write_zero_torque(void)
{
    if (ob->have_planar)
        planar_write_zero_torque();
    if (ob->have_wrist)
        wrist_write_zero_torque();
    if (ob->have_ankle)
        ankle_write_zero_torque();
    //    if (ob->have_linear)
    //        linear_write_zero_force();
    if (ob->have_hand)
        hand_write_zero_force();
}

void
after_compute_controls(void)
{
    if (ob->have_planar)
        planar_after_compute_controls();
    if (ob->have_wrist)
        wrist_after_compute_controls();
    if (ob->have_ankle)
        ankle_after_compute_controls();
    //    if (ob->have_linear)
    //        linear_after_compute_controls();
    if (ob->have_hand)
        hand_after_compute_controls();
}

// for ref recording
// after reading sensors, write them to the reference buffer array,

void
write_to_refbuf(void)
{
    if (ob->nwref < 1)
        return;
    if (ob->refwi >= REFARR_ROWS)
        return;                                  // overflow check

    if (ob->have_planar)
        planar_write_to_refbuf();
    if (ob->have_wrist)
        wrist_write_to_refbuf();
    if (ob->have_ankle)
        ankle_write_to_refbuf();
}

// for ref playback
// copy one sample from refbuf, and when you get to the end, loop back.

void
refbuf_to_refin(void)
{
    s32 j;

    if (ob->refri >= ob->refterm)                // overflow check, loop
        ob->refri = 0;

    for (j = 0; j < REFARR_COLS; j++)
        ob->refin[j] = refbuf->refarr[ob->refri][j];

    ob->refri++;
}

// hack refarr for smooth switchback

void
refarr_switchback(void)
{
    s32 i, j;
    s32 ticks;
    f64 head[REFARR_COLS], tail[REFARR_COLS], diff[REFARR_COLS];

    // don't let this operation overflow the buffer.
    if (ob->refwi > (REFARR_ROWS - 100)) {
        ob->refwi = REFARR_ROWS - 100;
    }
    // init head, tail, and diff
    for (i = 0; i < REFARR_COLS; i++) {
        head[i] = refbuf->refarr[0][i];
        tail[i] = refbuf->refarr[ob->refwi - 1][i];
        diff[i] = tail[i] - head[i];
    }

    ticks = 50;
    for (j = 0; j < ticks; j++) {
        for (i = 1; i < REFARR_COLS; i++) {
            refbuf->refarr[ob->refwi + j][i]
                = tail[i] - (diff[i] * (((f64) j) / ticks));
        }
        refbuf->refarr[ob->refwi + j][0] = tail[0] + j + 1;
    }

    ob->refterm = ob->refwi + 50;
}

/// read_sensors - read the various sensors, a/d, dio, tachometer, etc.

void
read_sensors(void)
{
    if (ob->sim.sensors)
        return;

    can_get_pos_reply();
    uei_ain_read();
    uei_dio_scan();
    pci4e_encoder_read();
    write_to_refbuf();
}

void
compute_controls(void)
{
    vibrate();

    if (ob->have_ft) {
        adc_ft_sensor();
    }

    if (ob->have_planar) {
        encoder_sensor();
	tach_sensor();
    }

    if (ob->have_wrist) {
        wrist_sensor();
        wrist_calc_vel();
        wrist_moment();
    }

    if (ob->have_grasp) {
        adc_grasp_sensor();
    }

    if (ob->have_ankle) {
        ankle_sensor();
        ankle_calc_vel();
        ankle_moment();
    }
    //    if (ob->have_linear) {
    //        linear_sensor();
    //        linear_calc_vel();
    //    }

    if (ob->have_hand) {
        hand_sensor();
        hand_calc_vel();
    }
    //
    // later
    // simple_ctl used by dac_torque_ctl.

    do_slot();

    after_compute_controls();
}

void
write_actuators(void)
{
    if (ob->no_motors) {
        write_zero_torque();
        return;
    }

    if (ob->have_planar)
        dac_torque_actuator();
    if (ob->have_wrist)
        dac_wrist_actuator();
    if (ob->have_ankle)
        dac_ankle_actuator();
    //    if (ob->have_linear)
    //        dac_linear_actuator();
    if (ob->have_hand)
        dac_hand_actuator();
    return;
}

void
check_safety(void)
{
    if (ob->safety.override)
        return;
    if (ob->have_planar)
        planar_check_safety();
    if (ob->have_wrist)
        wrist_check_safety();
}

void
user_init(void)
{
    init_log_fns();
    init_ref_fns();
    init_slot_fns();
}

/// read_reference - read reference data from file

void
read_reference()
{
    // is ref outside the slot_fns array?
    if (ob->reffnid >= ARRAY_SIZE(ob->ref_fns)) {
        // yes, something is wrong.
        return;
    }
    // if there is a function for it in ref_fns, call it.
    if (ob->ref_fns[ob->reffnid]) {
        ob->ref_fns[ob->reffnid] ();
    }
}

/// write_log - write sample data to fifo for recording to disk

void
write_log()
{
    // is log outside the slot_fns array?
    if (ob->logfnid >= ARRAY_SIZE(ob->log_fns)) {
        // yes, something is wrong.
        return;
    }
    // if there is a function for it in log_fns, call it.
    if (ob->log_fns[ob->logfnid]) {
        ob->log_fns[ob->logfnid] ();
    }
}

/// do_time_after_sample - do housekeeping after sample

void
do_time_after_sample()
{
    ob->times.time_after_last_sample = ob->times.time_after_sample;
    ob->times.time_after_sample = rt_timer_tsc2ns(rt_timer_tsc());
    ob->times.time_delta_sample =
        ob->times.time_after_sample - ob->times.time_before_sample;

    ob->times.ns_delta_sample = (u32) ob->times.time_delta_sample;

    if (ob->times.ns_max_delta_sample < ob->times.ns_delta_sample)
        ob->times.ns_max_delta_sample = ob->times.ns_delta_sample;
    if (ob->times.ns_delta_sample > (ob->times.ns_delta_sample_thresh * ob->irate / 100)) {
        do_error(WARN_MAIN_SLOW_SAMPLE);
    }

    // make persistent copies of these, so we don't need to worry
    // about timing when we use them.
    ob->wshm_count = ob->wshm_count_accum;
    ob->rshm_count = ob->rshm_count_accum;
    rob->can.recv_count = rob->can.recv_count_accum;

    ob->wshm_count_accum = 0;
    ob->rshm_count_accum = 0;
    rob->can.recv_count_accum = 0;
}

/// wait_for_tick - wait for thread to wake up again

void
wait_for_tick()
{
    s32 ret;

    ret = rt_task_wait_period(NULL);
}

// initialize constant array

static s32 carr[] = {
    1867345481, 1852795252, 1869750322, 544501602,
    1953724787, 1931504997, 2004117103, 174420577,
    1953067607, 544105844, 1092647266, 1701995630,
    1632903287, 1852141166, 1836409186, 1920215072,
    1629497698, 1142973550, 1701408353, 541925484,
    1668641348, 745694571, 778588192, 673197636,
    694447460, 1886339850, 1734963833, 840987752,
    741552176, 825242144, 1850286131, 1634887028,
    1986622563, 1867325541, 1852795252, 1667585056,
    1819242088, 1701406575, 1226845299, 170812270,
    1702125911, 2003793010, 1293954158, 1428171841,
    1745502547, 980448372, 2004299567, 1852386935,
    1634887028, 1986622563, 1869426021, 1852795252,
    1836016430, 1819033866, 1734963744, 544437352,
    1702061426, 1684371058, 10,
};

// make sure it's there

void
docarr(void)
{
    s32 i;
    s32 sum = 0;
    for (i = 0; i < ARRAY_SIZE(carr); i++) {
        sum += carr[i];
    }
}

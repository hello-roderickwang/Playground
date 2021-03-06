// robdecls.h - data declarations for the InMotion2 robot software system
//

// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#ifndef ROBDECLS_H
#define ROBDECLS_H

//#include "ruser.h"
#include <math.h>

// close to zero, for double compares.
#define EPSILON 0.0000001

#define ROBOT_LOOP_THREAD_NAME "IMT Robot Control Loop"

#define ARRAY_SIZE(a) (sizeof (a) / sizeof ((a)[0]))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) < (b) ? (a) : (b))
// u8/s8 etc. are defined in types.h

// I tripped over an f32, so I'm removing them
// typedef float f32;
#define f32 woops!

#define FIFOLEN 0x4000

// the Refbuf buffer will store 4 minutes of refs,
// each ref row will have 5 items
#define REFARR_COLS 5
#define REFARR_ROWS (200*60*4)

// errors, see main.c and uei.c
// if you change this, you MUST change tools/errpt

enum {
    ERR_NONE = 0,
    ERR_MAIN_LATE_TICK,
    WARN_MAIN_SLOW_TICK,
    WARN_MAIN_SLOW_SAMPLE,
    ERR_UEI_NSAMPLES,
    ERR_UEI_RET,
    ERR_UEI_BOARD_RANGE,
    ERR_UEI_BAD_ARRAY_PTRS,
    WARN_MAIN_FAST_TICK,
    ERR_AN_HIT_STOPS,
    ERR_AN_SHAFT_SLIP_LEFT,
    ERR_AN_SHAFT_SLIP_RIGHT,
    ERR_PL_ENC_KICK,
    ERR_CAN_MISSED_TICK,
    ERR_LAST
};

#define CAN_HEARTBEAT_INTERVAL_MS 100
typedef enum {
    CAN_HEARTBEAT_DISABLE = 0,
    CAN_HEARTBEAT_ENABLE = CAN_HEARTBEAT_INTERVAL_MS * 125 / 100,
    CAN_HEARTBEAT_FORCEFAIL = 1
} can_heartbeat_mode_t;

// math

// 2d
typedef struct xy_s {
    f64 x;
    f64 y;
} xy;

// 3d
typedef struct xyz_s {
    f64 x;
    f64 y;
    f64 z;
} xyz;

// shoulder/elbow pair
typedef struct se_s {
    f64 s;
    f64 e;
} se;

// 2x2 matrix
typedef struct mat22_s {
    f64 e00;
    f64 e01;
    f64 e10;
    f64 e11;
} mat22;

// performance metrics
typedef struct pm_s {
    f64 active_power;                            // pm2a
    f64 robot_power;                             // pm2a
    f64 min_jerk_deviation;                      // pm2b
    f64 min_jerk_dgraph;                         // graph
    f64 jerkmag;                                 // graph
    f64 dist_straight_line;                      // pm3
    f64 max_dist_along_axis;                     // pm4
    f64 min_dist_from_target;                    // new pm4
    f64 max_vel;
    u32 npoints;                                 // npts
    u32 five_d;                                  // planarwrist adaptive
    u32 done_npoints;
    f64 done_active_power;
    f64 done_robot_power;
    f64 done_min_jerk_deviation;
    f64 done_min_jerk_dgraph;
    f64 done_jerkmag;
    f64 done_max_vel;
    f64 done_dist_straight_line_sq;
    f64 done_max_dist_along_axis;
    f64 done_min_dist_from_target;
    f64 done_hand_pct_in;
    f64 done_hand_pct_out;
} PM;

// wrist types

// right/left dof
typedef struct rl_s {
    f64 r;
    f64 l;
} rl;

// wrist motors
typedef struct rlps_s {
    f64 r;                                       // right
    f64 l;                                       // left
    f64 ps;                                      // pronation/supination
} rlps;

// wrist dofs
typedef struct wrist_dof_s {
    f64 fe;                                      // flexion/extension
    f64 aa;                                      // abduction/adduction
    f64 ps;                                      // pronation/supination
} wrist_dof;

// wrist motor attributes
typedef struct wrist_mattr_s {
    u32 enc_channel;                             // encoder input channel
    f64 disp;                                    // displacement
    f64 vel;                                     // velocity
    f64 fvel;                                    // filtered velocity
    f64 devtrq;                                  // device torque
    f64 xform;                                   // torque transform
    f64 enc_xform;                               // encoder transform
    f64 bias;                                    // bias
    f64 volts;                                   // command voltage
    f64 test_volts;                              // test voltage
    f64 torque;                                  // current sensor input torque
    u32 ao_channel;                              // analog output channel
} wrist_MAttr;

// wrist gear ratios
typedef struct wrist_gears_s {
    f64 diff;                                    // differential
    f64 ps;                                      // pronation/supination
} wrist_gears;

// wrist attributes
typedef struct wrist_s {
    wrist_MAttr left;                            // dof
    wrist_MAttr right;                           // dof
    wrist_MAttr ps;                              // dof
    wrist_gears gears;                           // gear ratios
    u32 uei_ao_board_handle;                     // handle of the ao8 board
} Wrist;

typedef struct wrist_ob_s {                      // world coordinate parameters
    wrist_dof pos;                               // position
    wrist_dof vel;                               // velocity
    wrist_dof fvel;                              // filtered velocity
    wrist_dof accel;                             // acceleration
    wrist_dof jerk;                              // jerk
    wrist_dof torque;                            // command torque
    wrist_dof offset;                            // offset from zero;
    wrist_dof moment_cmd;
    wrist_dof back;                              // back wall for adap
    wrist_dof norm;                              // normalized posn for adap
    wrist_dof ref_pos;                           // for ref control
    f64 diff_stiff;                              // stiffness
    f64 ps_stiff;                                // stiffness
    f64 diff_side_stiff;                         // stiffness
    f64 diff_damp;                               // damping
    f64 ps_damp;                                 // damping
    f64 diff_gcomp;                              // gravity compensation
    f64 ps_gcomp;                                // gravity compensation
    u32 ps_adap_going_up;                        // adaptive going up
    u32 nocenter3d;                              // don't center the uncontrolled dof
    f64 velmag;                                  // velocity magnitude
    f64 accelmag;                                // acceleration magnitude
    f64 jerkmag;                                 // jerk magnitude
    f64 rl_pfomax;                               // preserve force orientation
    f64 rl_pfotest;                              // preserve force orientation
    u32 ft_motor_force;                          // use motor force instead of ft
} wrist_ob;

typedef struct wrist_prev_s {                    // previous world coordinate parameters
    wrist_dof pos;
    wrist_dof vel;
    wrist_dof fvel;
    wrist_dof accel;
    wrist_MAttr right;
    wrist_MAttr left;
    wrist_MAttr ps;
} wrist_prev;

// ankle types

typedef struct ankle_dof_s {                     // ankle degrees of freedom
    f64 dp;                                      // dorsiflexion/plantarflexion
    f64 ie;                                      // inversion/eversion
} ankle_dof;

typedef struct ankle_mattr_s {                   // ankle motor attributes
    u32 enc_channel;
    f64 disp;
    f64 devtrq;
    f64 xform;
    f64 volts;
    f64 test_volts;
    f64 force;
    u32 ao_channel;
    u32 rot_enc_channel;
    f64 rot_disp;
    f64 rot_lin_disp;
    f64 rot_lin_vel;
    f64 vel;
} ankle_MAttr;

typedef struct ankle_trans_s {                   // ankle gear ratios from motor to world
    f64 ratio;
    f64 lead;
    f64 ankle_ball_length;
    f64 ball_ball_width;
    f64 av_shin_length;
    f64 av_actuator_length;
    f64 enc_xform;
    f64 slip_thresh;
} ankle_trans;

typedef struct ankle_knee_s {
    u32 channel;
    f64 raw;
    // xform1 * potvoltage^2 + xform2 * potvoltage + bias
    f64 xform1;
    f64 xform2;
    f64 bias;
    f64 gain;
    f64 angle;
} ankle_knee;

typedef struct ankle_s {                         // group the parameters of each motor and
    // include an overall gear ratio for the differential
    ankle_MAttr left;
    ankle_MAttr right;
    ankle_trans trans;
    ankle_knee knee;
    u32 uei_ao_board_handle;
} Ankle;

typedef struct ankle_ob_s {                      // ankle world coordinates
    ankle_dof pos;
    ankle_dof vel;
    ankle_dof fvel;
    ankle_dof torque;
    ankle_dof back;
    ankle_dof norm;
    ankle_dof offset;
    ankle_dof ref_pos;
    ankle_dof moment_cmd;
    ankle_dof accel;
    ankle_dof ft_torque;
    f64 vel_mag;
    f64 accel_mag;
    f64 safety_vel;
    f64 safety_accel;
    f64 stiff;
    f64 damp;
    f64 rl_pfomax;
    f64 rl_pfotest;
    u32 ueimf;
    f64 Fitts_target_marker;
} ankle_ob;

typedef struct ankle_prev_s {                    // previous ankle world coordinate parameters
    ankle_dof pos;
    ankle_dof vel;
    ankle_dof fvel;
    rl rot_lin_disp;
    rl disp;
} ankle_prev;

// linear types

typedef struct linear_mattr_s {                  // linear motor attributes
    u32 enc_channel;                             // counter card encoder channel
    f64 disp;                                    // displacement
    f64 devfrc;                                  // output forces
    f64 xform;                                   // xform from force to voltage
    f64 volts;                                   // output voltage
    f64 test_volts;                              // test voltage
    u32 ao_channel;                              // ao board output voltage channel
    u32 limit_channel;
    f64 limit_volts;
} linear_MAttr;

typedef struct linear_gears_s {                  // linear gear ratios from motor to world
    f64 ratio;
} linear_gears;

typedef struct linear_s {                        // linear
    linear_MAttr motor;
    linear_gears gears;
    u32 uei_ao_board_handle;
} Linear;

typedef struct linear_ob_s {                     // linear world coordinates
    f64 pos;
    f64 vel;
    f64 fvel;
    f64 force;
    f64 back;                                    // back wall for adap
    f64 norm;                                    // normalized posn for adap
    f64 offset;
    f64 ref_pos;
    f64 stiff;
    f64 damp;
    f64 force_bias;
    f64 pfomax;                                  // pfo
    f64 pfotest;                                 // pfo
    u32 adap_going_up;
} linear_ob;

typedef struct linear_prev_s {                   // previous linear world coordinate parameters
    f64 pos;
    f64 vel;
    f64 fvel;
} linear_prev;

// hand types

typedef struct hand_mattr_s {                    // hand motor attributes
    u32 enc_channel;                             // counter card encoder channel
    f64 disp;                                    // displacement
    f64 devfrc;                                  // output forces
    f64 xform;                                   // xform from force to voltage
    f64 scale;                                   // encoder xform
    f64 bias;                                    // bias from force to voltage
    f64 volts;                                   // output voltage
    f64 test_volts;                              // test voltage
    u32 ao_channel;                              // ao board output voltage channel
    u32 limit_channel;
    f64 limit_volts;
} hand_MAttr;

typedef struct hand_gears_s {                    // hand gear ratios from motor to world
    f64 xform;                                   // encoder to gear
    f64 disp_xform;                              // gear to world
    f64 offset;
    f64 span;
    f64 gap;
    f64 ratio;
} hand_gears;

typedef struct hand_s {                          // hand
    hand_MAttr motor;
    hand_gears gears;
    u32 uei_ao_board_handle;
} Hand;

typedef struct hand_ob_s {                       // hand world coordinates
    f64 pos;
    f64 vel;
    f64 fvel;
    f64 force;
    f64 grasp;
    f64 ref_pos;
    f64 stiff;
    f64 damp;
    f64 force_bias;
    f64 pfomax;                                  // pfo
    f64 pfotest;                                 // pfo
    u32 adap_going_up;
    f64 active_power;
    u32 npoints;
} hand_ob;

typedef struct hand_prev_s {                     // previous hand world coordinate parameters
    f64 pos;
    f64 vel;
    f64 fvel;
} hand_prev;


// globals
// robot attributes

// motor attributes
typedef struct mattr_s {
    // input
    u32 channel;
    f64 xform;
    f64 offset;

    // output
    f64 raw;                                     // raw data
    f64 rad;                                     // radians
    f64 deg;                                     // degrees
    f64 cal;                                     // calibration value in radians
} MAttr;

// motor thermal model
typedef struct thermal_model_s {
    f64 tmass_winding;                           // thermal mass, winding
    f64 tmass_case;                              // thermal mass, case
    f64 tmpr_winding;                            // temperature, winding
    f64 tmpr_case;                               // temperature, case
    f64 tres_winding;                            // thermal resistance, winding to case
    f64 tres_case;                               // thermal resistance, case to ambient

    f64 alpha;                                   // temperature coefficient of resistance, copper
    f64 res0;                                    // initial resistance
    f64 trans_cond;                              // transconductance, volts to amps
    f64 reduction;                               // peak - sustained current level
    f64 max_tmpr;                                // max temp for peak current level
    f64 trange;                                  // temp range for current reduction
} Tm;

// motor
typedef struct motor_s {
    MAttr angle;
    MAttr vel;
    MAttr torque;
    Tm tm;
} Motor;

// Force Transducer
typedef struct ft_s {
    u32 have_rotmat;                             // use matrix instead of flip/vert/offset
    u32 rotmat_setup_done;

    // new style rotate
    xyz rot;                                     // input angles that are turned into rotmat
    xyz pre_jac;                                 // angles after rotation but before jacobean
    f64 rotmat[3][3];
    u32 channel[6];                              // adc channels
    u32 righthand;                               // flip matrix for right hand rule

    // old style rotate
    u32 flip;                                    // ft is installed upside down
    u32 vert;                                    // ft is installed vertically as on integrated planar wrist

    f64 offset;                                  // ft rotation in radians

    f64 curr[6];                                 // values after conversion to world space
    f64 prev[6];

    f64 filt[6];                                 // butterworth of curr
    f64 prevf[6];

    xyz world;                                   // filtered values world space
    xyz dev;                                     // filtered values device space
    xyz moment;                                  // moment values

    f64 xymag;                                   // force magnitude in xy

    u32 dobias;                                  // copy current raw to bias
    f64 raw[6];                                  // raw unbiased (for calibration)
    f64 cooked[6];                               // voltages after bias is applied
    f64 bias[6];                                 // bias voltages
    f64 scale[6];                                // scale and cal matrixes
    f64 cal[6][6];                               //   supplied with each ft by manufacturer

    f64 avg[6];                                  // various filtering choices
    f64 but[6];
    f64 sg[6];
    f64 sghist[6][64];
    f64 bsrawhist[6][16];
    f64 bsfilthist[6][16];
    f64 bs[6];
    u32 status;
} Ft;

// ATI ISA Force Transducer
typedef struct isaft_s {
    u16 cpf;                                     // (12-bit) counts per force (default units)
    u16 cpt;                                     // (12-bit) counts per torque (default units)
    u16 units;                                   // the default units for the calibration
    // (1=lbf,lbf-in; 2=N,N-mm; 3=N,N-m;
    // 4=Kg,Kg-cm; 5=Klbf,Klbf-in)

    s32 iraw[8];                                 // raw 12 bit data 
    f64 raw[8];                                  // raw voltage
} ISAFt;

// IMT Grasp sensor
typedef struct grasp_s {
    u32 channel;                                 // adc channel
    f64 raw;                                     // volts before bias
    f64 bias;                                    // bias
    f64 cal;                                     // calibration (raw * gain)
    f64 gain;
    f64 force;
} Grasp;

// Accelerometer
typedef struct accel_s {
    u32 channel[3];                              // adc channels

    f64 raw[3];                                  // voltages after bias is applied

    f64 curr[3];                                 // raw values after conversion to world space
    f64 prev[3];

    f64 filt[3];                                 // butterworth of curr
    f64 prevf[3];

    xyz world;                                   // filtered values world space
    xyz dev;                                     // filtered values device space

    f64 bias[3];                                 // bias voltages
    f64 xform;                                   // xform
} Accel;

// US Digital PC7266 ISA counter card for incremental encoders
typedef struct pc7266_s {
    s32 raw[4];                                  // raw 24 bit int values
    f64 enc[4];                                  // scaled float values
    f64 lenc[4];                                 // scaled float values
    f64 scale;                                   // scale multiplier
    u32 max;                                     // normalize from 0-max to -max/2 to max/2
    u32 zero;                                    // set to 1 to zero counters
    u32 docal;                                   // register index, see code
    u32 have;
} PC7266;

// US Digital PCI4E PCI counter card for incremental encoders
typedef struct pci4e_s {
    struct pci_dev *dev;

    u32 bar;
    u32 len;
    void *remap;

    s32 raw[4];                                  // raw 24 bit int values, 32-bit sign fixed
    f64 enc[4];                                  // scaled float values rotary
    f64 lenc[4];                                 // scaled float values linear
    s32 ret[4];                                  // error return values
    s32 lastret[4];                              // last error return value
    u32 nerrs[4];                                // error count
    u32 setct[4];                                // set offset
    f64 scale;                                   // scale multiplier
    u32 limit;                                   // modulus
    u32 zero;                                    // set to 1 to zero counters
    u32 dosetct;                                 // set to 1 to zero counters
    u32 have;
} PCI4E;

typedef struct can_s {
    s32 fd;                                      // sync file descriptor
    s32 posfd;                                   // pos file descriptor
    s32 axis;                                    // motor axis
    s32 value[8];                                // data value
    s32 pos_raw[8];                              // primary encoder
    s32 pos2_raw[8];                             // secondary encoder
    s32 setct[8];                                // encoder set count
    s16 analog1[8];                              // analog in 1
    s16 analog2[8];                              // analog in 2
    s32 vel_raw[8];
    s32 read_error;
    s32 status[8];
    u32 bitmask;                                 // node bitmask
    s32 recv_count_accum;                        // CAN packets received
    s32 recv_count;                              // persistent version
    hrtime_t pos_sync_time;                      // time of last sent sync
    hrtime_t pos_time[8];                        // pos delta time
    hrtime_t max_pos_time;                       // max pos delta time
    hrtime_t pos_wait_time;                      // wait for can pos

} CAN;

// robot
typedef struct robot_s {
    s8 tag[8];                                   // unused
    Motor shoulder;
    Motor elbow;

    se link;

    xy offset;

    Ft ft;

    ISAFt isaft;

    Grasp grasp;

    Accel accel;

    PCI4E pci4e;

    CAN can;

    Wrist wrist;

    Ankle ankle;

    Linear linear;

    Hand hand;
} Robot;

// time vars

typedef struct time_s {
    hrtime_t time_at_start;
    hrtime_t time_before_sample;
    hrtime_t time_after_sample;
    hrtime_t time_before_last_sample;
    hrtime_t time_after_last_sample;
    hrtime_t time_delta_sample;
    hrtime_t time_before_send_sync;
    hrtime_t time_delta_tick;
    hrtime_t time_delta_call;
    hrtime_t time_since_start;

    u32 ns_delta_call;
    u32 ns_delta_tick;
    u32 ns_delta_tick_thresh;
    u32 ns_delta_sample;
    u32 ns_delta_sample_thresh;
    u32 ms_since_start;
    u32 sec;

    u32 ns_max_delta_tick;
    u32 ns_max_delta_sample;
} Timev;

// data that gets copied to ob atomically, when you set go

typedef struct restart_s {
    u32 go;                                      // write this last!
    u32 Hz;                                      // when you're ready to go,
    u32 ovsample;
    f64 stiff;                                   // copy all this to ob.
    f64 damp;
} Restart;

typedef struct ref_s {
    xy pos;
    xy vel;
} Ref;

typedef struct spring_s {
    se ref;
    se stiff;
    se disp;
    xy dispxy;
} Spring;

typedef struct max_s {
    xy vel;
    xy motor_force;
    se motor_torque;
} Max;

// this needs to be extended for > 2d position descriptions

typedef struct box_s {
    xy point;
    f64 w;                                       // width
    f64 h;                                       // height
} box;

typedef struct slot_s {
    u32 id;                                      // id (for copy_slot)

    // a la for loop
    u32 i;                                       // the incremented index
    u32 incr;                                    // amount to increment each sample
    u32 term;                                    // termination
    u32 termi;                                   // index incremented after termination
    // for making controls stiffer, etc.

    box b0;                                      // initial position
    box b1;                                      // final position
    box bcur;                                    // current position

    f64 rot;                                     // slot rotation in radians
    u32 fnid;                                    // index into slot fn * table
    u32 running;                                 // this slot is running
    u32 go;                                      // go (for copy_slot)
} Slot;

typedef struct pos_error_s {
    u32 mod;
    f64 dx;
    f64 dy;
} Pos_error;



// safety envelope
typedef struct safety_s {
    f64 pos;
    f64 vel;
    f64 torque;
    f64 ramp;
    f64 damping_nms;
    f64 velmag_kick;
    u32 override;

    u32 planar_just_crossed_back;
    u32 was_planar_damping;
    u32 damp_ret_ticks;
    f64 damp_ret_secs;
} Safety;

typedef struct sim_s {
    u32 sensors;                                 // boolean, yes, simulate
    xy pos;                                      // position, read from user space
    xy vel;                                      // vel
    wrist_dof wr_pos;                            // wrist position
    wrist_dof wr_vel;                            // wrist velocity
} Sim;

#define N_UEIDAQ_BOARDS 4
#define UEI_SAMPLES 16
#define DAQ_ACQUIRE 1
#define DAQ_RELEASE 0


// contains s32 data from the daq
typedef struct daq_s {
    s8 tag[8];                                   // unused
    s32 n_ueidaq_boards;                         // number of UEI boards in system
    s32 uei_board[N_UEIDAQ_BOARDS];              // mapping from logical (array) to physical (bus)
    s32 ain_handle[N_UEIDAQ_BOARDS];             // Handles returned by PdAcquireSubsystem
    s32 aout_handle[N_UEIDAQ_BOARDS];
    s32 din_handle[N_UEIDAQ_BOARDS];             // Handles returned by PdAcquireSubsystem
    s32 dout_handle[N_UEIDAQ_BOARDS];
    s32 ao8_handle[N_UEIDAQ_BOARDS];
    u32 adapter_type[N_UEIDAQ_BOARDS];           // adapter type to identify board

    s32 ain_cl_size;                             // channel list size
    s32 ain_ret;                                 // return from pd_ain_get_samples()
    u32 ain_got_samples;                         // number of samples returned
    u32 ain_cfg;                                 // SINGLE_ENDED?  5/10V?
    u32 ain_slowbit;                             // use slow bit?
    f64 ain_bias_comp[N_UEIDAQ_BOARDS];          // bias voltage compensation ~ .018

    // in the shoulder/elbow robot:
    // 2 dio vars are used for encoder input
    // up to 16 adc are used for tach input, etc.
    // 2 dac are used for torque output to motors

// up to 4 boards * 16 samples each.
// single dim arrays are easier to handle here.

    // two-dimensional arrays
    u16 m_dienc[N_UEIDAQ_BOARDS][2];             // digital inputs
    u16 m_dout_buf[N_UEIDAQ_BOARDS];             // digital outputs
    u16 m_adc[N_UEIDAQ_BOARDS][UEI_SAMPLES];     // analog inputs
    u16 m_dac[N_UEIDAQ_BOARDS][UEI_SAMPLES];     // analog outputs

    f64 m_adcvoltsmean[N_UEIDAQ_BOARDS][UEI_SAMPLES];   // adc mean
    f64 m_adcvoltsmed[N_UEIDAQ_BOARDS][UEI_SAMPLES];    // adc median

    f64 m_adcvoltsprev[N_UEIDAQ_BOARDS][UEI_SAMPLES];   // adc filter stuff
    f64 m_adcvoltsfilt[N_UEIDAQ_BOARDS][UEI_SAMPLES];
    f64 m_adcvoltspfilt[N_UEIDAQ_BOARDS][UEI_SAMPLES];

    f64 m_adcvolts[N_UEIDAQ_BOARDS][UEI_SAMPLES];
    f64 m_dacvolts[N_UEIDAQ_BOARDS][UEI_SAMPLES];

    // one dimensional pointers, see main..c:main_init()
    u16 *dienc;
    u16 *dout_buf;
    u16 *adc;
    u16 *dac;

    f64 *adcvolts;
    f64 *dacvolts;

    f64 *adcvoltsmean;
    f64 *adcvoltsmed;

    f64 *adcvoltsprev;
    f64 *adcvoltsfilt;
    f64 *adcvoltspfilt;

    // the two digital output bits on the junction box
    u16 dout0;
    u16 dout1;

    u16 dout_latch;

    // di status bits
    u16 distat[2];

    // digital inputs, used for reading planar encoders
    u16 prev_dienc[2];                           // for calculating velocity
    s32 dienc_vel[2];                            // raw velocity
    s32 prev_dienc_vel[2];                       // for calculating accelleration
    s32 dienc_accel[2];                          // raw accelleration

    u32 diovs;                                   // encoder oversampling
} Daq;

// the main object struct

typedef struct ob_s {
    s8 tag[8];                                   // unused
    RT_TASK main_thread;

    u32 doinit;                                  // run init code if set.
    u32 didinit;                                 // so we only init once
    u32 quit;                                    // quit program if set.

    u32 i;                                       // loop iteration number.
    u32 fasti;                                   // fast tick count for ft
    u32 samplenum;                               // sample number.

    u32 total_samples;                           // stop after this many

    u32 Hz;                                      // samples per second
    // following are derived.
    f64 rate;                                    // 1.0/(samples per second),
    u32 irate;                                   // BILLION/(samples per second),
    // i.e. nanoseconds per sample

    // for oversampled ft sampling
    u32 ovsample;                                // oversampling multiplier
    // set ovsample, the following are derived.
    u32 fastHz;                                  // fast samples per second
    f64 fastrate;                                // 1.0/(samples per second),
    u32 fastirate;                               // BILLION/(samples per second),
    // i.e. nanoseconds per sample

    f64 stiff;                                   // stiffness for controller
    f64 damp;                                    // damping
    f64 curl;                                    // curl
    f64 friction;                                // friction
    f64 friction_gap;                            // friction_gap

    xy const_force;                              // constant force control

    f64 side_stiff;                              // side stiffness for adapative controller

    f64 pfomax;                                  // preserve force orientation max
    f64 pfotest;                                 // pfo test value

    se dvolts;                                   // impulse threshold delta volts
    f64 impulse_thresh_volts;                    // impulse threshold cutoff

    u32 busy;                                    // sample is not in sleep wait.
    u32 paused;                                  // tick clock, but don't write actuators
    u32 fault;                                   // control loop triggered fault
    s32 stiffener;                               // a stiffness % increment
    // 0 is normal stiffness
    // -100 is no stiffness
    // 100 is double, 200 is triple
    // generalizing slot_term_stiffen
    s32 stiff_delta;                             // how much to add to stiffener each tick
    u32 no_motors;                               // never write torques

    Restart restart;                             // copied into Ob on restart.

    Timev times;                                 // timing vars

    u32 have_uei;                                // we have uei boards
    // have_uei not in imt2.cal, it's detected in main.
    u32 have_tach;                               // we have a tachometer
    u32 have_ft;                                 // we have a non-ISA force transducer
    u32 have_isaft;                              // we have an ISA force transducer
    u32 have_accel;                              // we have an acceleromter
    u32 have_grasp;                              // we have a grasp sensor
    u32 have_planar;                             // we have a planar robot
    u32 have_wrist;                              // we have a wrist robot
    u32 have_ankle;                              // we have an ankle robot
    u32 have_linear;                             // we have an linear robot
    u32 have_hand;                               // we have a hand robot
    u32 have_planar_incenc;                      // we have a planar with incr encoders 
    u32 have_planar_ao8;                         // we have a planar with ao8 output
    u32 have_mf_aout_for_dout;                   // we use the mf aouts for douts
    u32 have_thermal_model;                      // we have thermal model calcs
    u32 have_can;                                // we have CAN I/O

    u32 ankle_debug_position;                    // PX in 2nd position

    u32 asciilog;                                // ascii log files
    u32 targetnumber;                            // target number for multilog

    Slot copy_slot;                              // for input from shm
    Slot slot[8];                                // slot control
    Pos_error pos_error;                         // inject position errors
    PM pm;                                       // performance metrics for adaptive
    void (*slot_fns[128]) (u32);                 // array of slot functions

    u32 slot_max;                                // max number of slots;

    f64 pi;                                      // pi (make sure trig works)

    u32 nlog;                                    // number of items to write out
    f64 log[32];                                 // array of items to write out
    void (*log_fns[128]) (void);                 // array of log functions
    u32 logfnid;                                 // which log function in array

    u32 ndisp;                                   // number of items to write out
    f64 disp[32];                                // array of items to write out

    Ref ref;                                     // references for logfile playback
    Spring spring;                               // simple spring control vars

    u32 refri;                                   // refarr read index
    u32 refwi;                                   // refarr write index
    u32 refterm;                                 // refarr index of last entry

    u32 nwref;                                   // number of items write to the ref buf
    u32 nrref;                                   // number of items to read from the ref buf

    f64 refin[32];                               // array of items to read
    void (*ref_fns[128]) (void);                 // array of ref functions
    u32 reffnid;                                 // which log function in array
    u32 ref_switchback_go;                       // run the switchback fn

    RT_PIPE dififo;                              // data in (like stdin)
    RT_PIPE dofifo;                              // data out (stdout)
    RT_PIPE eofifo;                              // error out (stderr)
    RT_PIPE cififo;                              // command in
    RT_PIPE ddfifo;                              // display data out
    RT_PIPE tcfifo;                              // tick data out
    RT_PIPE ftfifo;                              // tick data out

    u32 ntickfifo;                               // do the tcfifo output
    u32 fttickfifo;                              // do the ftfifo output

    u32 fifolen;                                 // fifo buffer size
    s8 *ci_fifo_buffer;                          // pointer to command input fifo buffer
    // (handled differently from other fifos)

    Safety safety;                               // safety zone variables

    u32 vibrate;                                 // random vibration factor for testing
    s32 xvibe;                                   // vibration components
    s32 yvibe;
    // stuff for spring tests
    f64 tsvibe;
    f64 tevibe;
    f64 txvibe;
    f64 tyvibe;
    f64 tvibamp;

    xy pos;                                      // world position
    xy tach_vel;                                 // world velocities from hardware tach
    xy ftach_vel;                                // filtered tach_vel
    xy soft_vel;                                 // world velocities from position
    xy fsoft_vel;                                // filtered soft_vel
    xy vel;                                      // assigned from one of the vels
    xy motor_force;                              // world forces sent to motors, from controller
    se motor_torque;                             // device torques from motor_force
    se motor_volts;                              // device volts from motor_torque
    xy back;                                     // back wall for adap
    xy norm;                                     // normalized posn for adap

    f64 velmag;                                  // magnitude of the velocity

    xy soft_accel;                               // accel derived from position
    f64 soft_accelmag;                           // accel magnitude

    xy soft_jerk;                                // jerk derived from position
    f64 soft_jerkmag;                            // jerk magnitude

    se theta;                                    // encoder angles
    se thetadot;                                 // angular velocity
    se fthetadot;                                // filtered thetadot

    u32 planar_uei_ao_board_handle;              // handle of the ao8 board

    wrist_ob wrist;                              // world coordinates
    ankle_ob ankle;
    linear_ob linear;
    hand_ob hand;

    u32 test_raw_torque;                         // raw torque test mode;
    se raw_torque_volts;                         // raw volts for testing
    u32 test_no_torque;                          // don't write torques at all for testing

    Sim sim;                                     // simulate sensors

    xy req_pos;                                  // desired position from mouse

    f64 sin_period;                              // for the sinewave generator
    f64 sin_amplitude;                           // amplitude
    u32 sin_which_motor;                         // shoulder, elbow, neither, both

    u32 butcutoff;                               // butterworth cutoff W(n) * 100
    // for 200 Hz, 15Hz cutoff, use 15
    // (2 * 15 Hz cutoff) / 200 Hz

    Max max;                                     // maxima

    // see main:do_error() and calls to it.
    u32 errnum;                                  // error this sample (couldn't call it errno)
    u32 nerrors;                                 // cumulative number of errors
    u32 errori[128];
    u32 errorcode[128];
    u32 errorindex;                              // index into error arrays

    // scr is for random debugging
    f64 scr[64];                                 // scratch registers
    // game is for when programs game processes to communicate
    // with each other while the lkm is loaded.
    f64 aodiff[16];                              // for ao8 testing
    f64 aocum[16];
    f64 aorms[16];
    f64 aocum1[16];
    f64 aoavg[16];
    s32 aocount;

    f64 pl_stopspan;
    f64 pl_linkspan;
    f64 pl_vbig;
    f64 pl_vsmall;
    f64 pl_vtiny;
    f64 pl_slop;

    f64 ha_vbig;
    f64 ha_vsmall;
    f64 ha_slop;

    f64 wr_diffslop;
    f64 wr_psslop;
    f64 wr_rspan;
    f64 wr_lspan;
    f64 wr_psspan;
    f64 wr_vbig;
    f64 wr_vsmall;

    u32 naxes;                                   // axes available
    s32 wshm_count_accum;                        // introspection counts
    s32 rshm_count_accum;
    s32 rshm_count;                              // these are persistent.
    s32 wshm_count;

    u32 last_shm_val;                            // sanity check
} Ob;

typedef struct pcolor {
    float red;
    float green;
    float blue;
} Pcolor;

// values of data from previous sample, for filters etc.
// these get filled after read_sensors is done.

typedef struct prev_s {
    s8 tag[8];                                   // unused
    xy pos;
    xy vel;
    xy soft_accel;

    se theta;
    se thetadot;
    se fthetadot;

    xy soft_vel;
    xy fsoft_vel;

    xy tach_vel;
    xy ftach_vel;

    se volts;

    wrist_prev wrist;
    ankle_prev ankle;
    linear_prev linear;
    hand_prev hand;

} Prev;

typedef struct refbuf_s {
    f64 refarr[REFARR_ROWS][REFARR_COLS];
} Refbuf;

// 0x494D5431 is 'IMT1'
#define OB_KEY   0x494D5431
#define ROB_KEY  0x494D5432
#define DAQ_KEY  0x494D5433
#define PREV_KEY 0x494D5434
#define GAME_KEY 0x494D5435
#define REFBUF_KEY 0x494D5436

extern Ob *ob;
extern Daq *daq;
extern Prev *prev;
extern Robot *rob;
extern Refbuf *refbuf;

void check_safety(void);
void planar_check_safety(void);
void wrist_check_safety(void);

void user_init(void);

// slot.c
// void load_slot(u32, u32, u32, u32, void (*)(u32), s8 *);
void load_slot(u32, u32, u32, u32, u32, s8 *);
void do_slot(void);
void stop_slot(u32);
void stop_all_slots(void);

// main.c
void do_time_before_sample(void);
void check_quit(void);
void do_error(u32);
void notify_error(char *, char *);
void check_late(void);
void refarr_switchback(void);
void read_sensors(void);
void clear_sensors(void);
void print_sample_times(void);
void do_time_after_sample(void);
void wait_for_tick(void);

void read_reference(void);
void write_log(void);

void write_to_refbuf(void);
void refbuf_to_refin(void);
void planar_write_to_refbuf(void);
void wrist_write_to_refbuf(void);
void ankle_write_to_refbuf(void);

s32 init_module(void);
// void cleanup_module(void);
void cleanup_signal(s32);

void unload_module(void);
void start_routine(void *);
void shm_copy_commands(void);
void main_init(void);
void main_loop(void);
void rob_log(const char *, ...);

void docarr(void);

// math.c
xy jacob2d_x_p2d(mat22, se);
mat22 jacob2d_x_j2d(mat22, mat22);
mat22 jacob2d_inverse(mat22);
mat22 jacob2d_transpose(mat22);
xy xy_polar_cartesian_2d(se, se);
mat22 j_polar_cartesian_2d(se, se);
xy rotate2d(xy, f64);
xy xlate2d(xy, xy);
f64 xform1d(f64, f64, f64);
s32 ibracket(s32, s32, s32);
f64 dbracket(f64, f64, f64);
se preserve_orientation(se, f64);
f64 butter(f64, f64, f64);
f64 butstop(f64 *, f64 *);
f64 apply_filter(f64, f64 *);
f64 delta_radian_normalize(f64);
f64 radian_normalize(f64);
f64 min_jerk(f64, f64);
f64 i_min_jerk(u32, u32, f64);
f64 xasin(f64 x);
f64 xacos(f64 x);

// uei.c
void uei_ptr_init(void);
void uei_aio_init(void);
void uei_aio_close(void);
void uei_ain_read(void);
void uei_aout_write(f64, f64);
void test_uei_write(void);
void uei_dio_scan(void);
s32 uei_dout_write_masked(s32, u32, u32);
void uei_din_read(s32, u32 *);
void uei_dout01(s32);
void uei_aout32_test(void);
void uei_aout32_write(s32, u16, f64);
void cleanup_devices(void);

// pci4e.c
void pci4e_init(void);
void pci4e_close(void);
void pci4e_reset_all_ctrs(void);
void pci4e_set_all_ctrs(void);
s32 pci4e_safe_check(void);
void pci4e_encoder_read(void);
void pci4e_calib(void);

// sensact.c
void sensact_init(void);
void encoder_sensor(void);
void tach_sensor(void);
void adc_ft_sensor(void);
void fast_read_ft_sensor(void);
void ft_zero_bias(void);
void adc_grasp_sensor(void);
void adc_accel_sensor(void);

s32 can_init(void);
void can_close(void);
s32 can_mot_write(s32, s32);
s32 can_send_sync(void);
s32 can_pos_read(s32);

void dac_torque_actuator(void);
void set_zero_torque(void);
void write_zero_torque(void);
void vibrate(void);
void do_max(void);
void planar_set_zero_torque(void);
void planar_write_zero_torque(void);
void planar_after_compute_controls(void);

void wrist_set_zero_torque(void);
void wrist_write_zero_torque(void);
void wrist_init(void);
void wrist_after_compute_controls(void);
void wrist_sensor(void);
void wrist_moment(void);
void wrist_calc_vel(void);
void dac_wrist_actuator(void);

void ankle_set_zero_torque(void);
void ankle_write_zero_torque(void);
void ankle_init(void);
void ankle_after_compute_controls(void);
void ankle_sensor(void);
void ankle_moment(void);
void ankle_calc_vel(void);
void dac_ankle_actuator(void);

void linear_set_zero_force(void);
void linear_write_zero_force(void);
void linear_init(void);
void linear_after_compute_controls(void);
void linear_sensor(void);
void linear_calc_vel(void);
void dac_linear_actuator(void);

void hand_set_zero_force(void);
void hand_write_zero_force(void);
void hand_init(void);
void hand_after_compute_controls(void);
void hand_sensor(void);
void hand_calc_vel(void);
void dac_hand_actuator(void);

// pl_ulog.c
void init_log_fns(void);
void init_ref_fns(void);

// pl_uslot.c
void init_slot_fns(void);

// fifo.c
void init_fifos(void);
void cleanup_fifos(void);
void fifo_input_handler(void);
void print_fifo_input(void);

void set_ob_variable(void);
s32 get_option_x64(s8 **, u64 *);
s8 *get_options_x64(s8 *, s32, u64 *);

#include <stdio.h>
#include <unistd.h>
#include <syslog.h>
#include <rtdk.h>

#endif                          // ROBDECLS_H

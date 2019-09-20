// userfn.h - common prototypes

// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

void write_data_fifo_sample_fn(void);
void write_motor_test_fifo_sample_fn(void);
void write_actuators(void);
void check_safety(void);
void compute_controls(void);
void output_controls(void);
void init_log_fns(void);
void init_slot_fns(void);

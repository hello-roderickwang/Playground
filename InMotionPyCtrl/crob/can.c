// can.c - i/o for CAN networked devices
// part of the robot.o robot process

// InMotion2 robot system software

// Copyright 2011 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

// typedef int s32;
// typedef char s8;
// typedef unsigned long long u64;
// typedef u64 hrtime_t;

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"

#include <xenomai/rtdm/rtcan.h>

static struct can_frame frame;
static struct sockaddr_can to_addr;
static struct sockaddr_can recv_addr;

struct ifreq ifr;

char *rtcan_name = "rtcan0";

// should some of this stuff happen before the rt fork?

s32
can_init(void)
{
    s32 ret;

    if (!ob->have_can) return 0;

    // sync output socket
    ret = rt_dev_socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (ret < 0) {
        rob_log("%s:%d %s, rt_dev_socket: %s\n", __FILE__, __LINE__, __FUNCTION__, strerror(-ret));
        return -1;
    }
    rob->can.fd = ret;

    strncpy(ifr.ifr_name, rtcan_name, IFNAMSIZ);

    ret = rt_dev_ioctl(rob->can.fd, SIOCGIFINDEX, &ifr);
    if (ret < 0) {
        rob_log("%s:%d %s, rt_dev_ioctl: %s\n", strerror(-ret));
        goto failure;
    }

    memset(&to_addr, 0, sizeof(to_addr));
    to_addr.can_ifindex = ifr.ifr_ifindex;
    to_addr.can_family = AF_CAN;

    // pos input socket
    ret = rt_dev_socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (ret < 0) {
        rob_log("%s:%d %s, rt_dev_socket: %s\n", __FILE__, __LINE__, __FUNCTION__, strerror(-ret));
        return -1;
    }
    rob->can.posfd = ret;

    // read all CAN interfaces
    ifr.ifr_ifindex = 0;

    // bind RT CAN socket to receive address

    recv_addr.can_family = AF_CAN;
    recv_addr.can_ifindex = ifr.ifr_ifindex;
    ret = rt_dev_bind(rob->can.posfd, (struct sockaddr *) &recv_addr, sizeof(struct sockaddr_can));
    if (ret < 0) {
        rob_log("%s:%d %s, rt_dev_bind: %s\n", __FILE__, __LINE__, __FUNCTION__, strerror(-ret));
        goto failure;
    }

    return ret;

  failure:
    can_close();
    return -1;
}

s32
can_send_sync(void)
{
    s32 ret;
    static struct can_frame sync_frame;
    sync_frame.can_id = 0x80;
    sync_frame.can_dlc = 0;                      // 0 bytes
    rob->can.pos_sync_time = rt_timer_tsc2ns(rt_timer_tsc());
    ret = rt_dev_sendto(rob->can.fd, (void *) &sync_frame, sizeof(can_frame_t), 0,
                        (struct sockaddr *) &to_addr, sizeof(to_addr));
    return ret;
}

s32
can_send_heartbeat(void)
{
    s32 ret;
    static struct can_frame hb_frame;
    hb_frame.can_id = 0x700;
    hb_frame.can_dlc = 0;                      // 0 bytes
    ret = rt_dev_sendto(rob->can.fd, (void *) &hb_frame, sizeof(can_frame_t), 0,
                        (struct sockaddr *) &to_addr, sizeof(to_addr));
    return ret;
}

s32
can_set_heartbeat(can_heartbeat_mode_t can_heartbeat_mode)
{
    s32 i;
    s32 ret;
    static struct can_frame hbtime_frame;

    hbtime_frame.can_id = 0x600;
    hbtime_frame.can_dlc = 8;
    hbtime_frame.data[0] = 0x23;
    hbtime_frame.data[1] = 0x16;  // set object 0x1016
    hbtime_frame.data[2] = 0x10;
    hbtime_frame.data[3] = 0x01;  // subindex 1
    hbtime_frame.data[4] = can_heartbeat_mode;

    hbtime_frame.data[5] = 0;
    hbtime_frame.data[6] = 0;
    hbtime_frame.data[7] = 0;

    ret = rt_dev_sendto(rob->can.fd, (void *) &hbtime_frame, sizeof(can_frame_t), 0,
                        (struct sockaddr *) &to_addr, sizeof(to_addr));

    return ret;
}

// frame.can_id = 0xnnn
// frame.can_dlc = length
// frame.data[0] = XX
// frame.data[1] = XX
// fill frame.data with a function to copy in a signed or not
// 32, 16, or 8 bit val or vals.

// axis is 0 to 3.

s32
can_mot_write(s32 axis, s32 value)
{
    s32 i;
    s32 ret;

    if (axis <= 0)
        return 0;
    rob->can.axis = axis;
    rob->can.value[axis] = value;

    frame.can_id = 0x400 | (axis & 0xf);         // PDO can_id
    frame.can_dlc = 2;                           // write value is 2 bytes

    // pick frame data bytes out of rob->can.value[axis]
    for (i = 0; i < frame.can_dlc; i++) {
        frame.data[i] = (rob->can.value[axis] >> (8 * i)) & 0xff;
    }

    ret = rt_dev_sendto(rob->can.fd, (void *) &frame, sizeof(can_frame_t), 0,
                        (struct sockaddr *) &to_addr, sizeof(to_addr));

    return ret;
}

void
can_close(void)
{
    int ret;

    if (!ob->have_can) return;

    usleep(100000);

    if (rob->can.fd >= 0) {
        ret = rt_dev_close(rob->can.fd);
        rob->can.fd = -1;
        if (ret) {
            rob_log("%s:%d %s, rt_dev_close: %s\n", __FILE__, __LINE__, __FUNCTION__, strerror(-ret));
        }
    }
    if (rob->can.posfd >= 0) {
        ret = rt_dev_close(rob->can.posfd);
        rob->can.posfd = -1;
        if (ret) {
            rob_log("%s:%d %s, rt_dev_close: %s\n", __FILE__, __LINE__, __FUNCTION__, strerror(-ret));
        }
    }
}

// the can position message round trip time for this node
// is the current time minus the time that the last sync was sent.
void
pos_time(node)
{
    rob->can.pos_time[node] =
        (rt_timer_tsc2ns(rt_timer_tsc()) - rob->can.pos_sync_time) / 1000;
}

void
can_check_emergency(void) {
    // only repory error once.
    if (ob->paused) { return; }

    if ((frame.can_id & 0xfff0) == 0x080) {
        can_set_heartbeat(CAN_HEARTBEAT_FORCEFAIL);

        char failmsg[512];
        sprintf(failmsg, "Received an alert message 0x80 from motor (%#02x). Shutting down motor power.\\n"
            "\\nPlease shut down and restart the robot.\\n"
            "\\nIf the problem recurs, discontinue use and call Interactive Motion support.", frame.can_id & 0x7);

        notify_error("set-ready-dis", failmsg);
        ob->paused = 1;
    }
}

// do a looping non-blocking read until there's no data.
void
can_clear_input(void) {
    int ret;
    s32 s = rob->can.posfd;
    for (;;) {
        ret = rt_dev_recv(s, (void *) &frame, sizeof(can_frame_t), MSG_DONTWAIT);
        can_check_emergency();
        if (ret < 0) break;
	rob->can.recv_count_accum++;
    }
}

// set up bitmask based on robot channels (which are now CAN node ids)
// called by doinit, after reading cal file.
// node 1 = 0b0010 node 2 = 0b0100 etc.

void
can_init_bitmask(void) {
    u32 b = 0;

    if (ob->have_planar) {
	b |= 1 << rob->shoulder.angle.channel;
	b |= 1 << rob->elbow.angle.channel;
    }
    if (ob->have_hand) {
	b |= 1 << rob->hand.motor.enc_channel;
    }
    if (ob->have_wrist) {
	b |= 1 << rob->wrist.left.enc_channel;
	b |= 1 << rob->wrist.right.enc_channel;
	b |= 1 << rob->wrist.ps.enc_channel;
    }
    if (ob->have_ankle) {
	b |= 1 << rob->ankle.left.enc_channel;
	b |= 1 << rob->ankle.right.enc_channel;
    }

    if (ob->have_linear) {
	b |= 1 << rob->linear.motor.enc_channel;
    }
    rob->can.bitmask = b;
}

void
can_get_pos_reply(void) {
    int ret;
    s32 posnode;
    s32 need_pos;

    if (!ob->have_can) return;

    nanosecs_rel_t time_left;
    hrtime_t now;
    s32 s;

    u32 bitmask;

    // clear out any spurious/old messages.
    can_clear_input();

    // send the sync that triggers the position reply
    can_send_sync();

    s = rob->can.posfd;
    if (rob->can.pos_wait_time < 100) {
		rob->can.pos_wait_time = 3 * 1000;
    }

    need_pos = ob->naxes;

    // Clear can.read_error every 20 ticks (0.1 sec), so we can tolerate an occasional error
    // but still detect them quickly.
    if ((ob->i % 20) == 0 && !ob->paused) {	// once every 20 ticks 0.1 seconds.
	rob->can.read_error = 0;
    }

    // this code assumes that the whole control loop is only paying
    // attention to 0x380 position packets, and ignoring all others.
    // if we need to read other kinds of packets, we need to change
    // our strategy here.

    // finish the loop when the bitmask is clear.
    // this means we wait for one (or more) messages from each node,
    // and if any node does not respond before the rt_dev_recv timeout,
    // we can.read_error++.
    bitmask = rob->can.bitmask;
    while (bitmask) {
	// we give up on waiting for position
	// can_pos_wait_time microseconds after the sync.
	// thus time_left is the amount of time REMAINING until
	// that deadline: (sync time + duration of timeout) - now
	now = rt_timer_tsc2ns(rt_timer_tsc());
	time_left = (ob->times.time_before_send_sync
		     + (rob->can.pos_wait_time * 1000))
	             - now;
	rt_dev_ioctl(s, RTCAN_RTIOC_RCV_TIMEOUT, &time_left);

        // receive message from socket
        ret = rt_dev_recv(s, (void *) &frame, sizeof(can_frame_t), 0);

        if (ret < 0) {
	    rob->can.read_error++;
	    do_error(ERR_CAN_MISSED_TICK);

	    // Fail if we get more than 4 CAN read errors in 20 ticks.
	    if (rob->can.read_error > 4) {
		// probably -EAGAIN - the read timed out.
		if (!ob->paused) {   // we only want to do this once
		    can_set_heartbeat(CAN_HEARTBEAT_FORCEFAIL);

                    char failmsg[512];
                    sprintf(failmsg, "A servo failed to respond (%#02x). Shutting down motor power.\\n"
                        "\\nPlease shut down and restart the robot.\\n"
                        "\\nIf the problem recurs, discontinue use and call Interactive Motion support.", bitmask >> 1);

		    notify_error("set-ready-dis", failmsg);
		}
		ob->paused = 1;
	    }
	    break;	// to zero pos_time
	}
	rob->can.recv_count_accum++;

        can_check_emergency();

        // handle sync reply PDO
        if ((frame.can_id & 0xfff0) == 0x380) {
            posnode = frame.can_id & 0x7;
            pos_time(posnode);

            // no matter if we are ankle or not, the first half of the frame is position.
            rob->can.pos_raw[posnode] = (frame.data[3] << 24)
                + (frame.data[2] << 16)
                + (frame.data[1] << 8)
                + frame.data[0];

            // ankle debugging 
            if (ob->have_ankle && ob->ankle_debug_position) {
                rob->can.pos2_raw[posnode] = (frame.data[7] << 24)
                    + (frame.data[6] << 16)
                    + (frame.data[5] << 8)
                    + frame.data[4];
            } else {
                // position 2 is analog
                rob->can.analog1[posnode] = (frame.data[5] << 8) + frame.data[4];
                rob->can.analog2[posnode] = (frame.data[7] << 8) + frame.data[6];            
            }

	    // clear this node in bitmask
	    bitmask &= ~(1 << posnode);
        }
    }
    pos_time(0);
    rob->can.max_pos_time = MAX(rob->can.max_pos_time, rob->can.pos_time[0]);
}

// pci4e.c - US Digital PCI incremental encoder interface card
// http://www.usdigital.com/products/pci4e/
// part of the robot.o Linux Kernel Module

// InMotion2 robot system software 

// Copyright 2005 Interactive Motion Technologies, Inc.
// Cambridge, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <ctype.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/mman.h>

typedef unsigned int u32;
typedef int s32;
typedef double f64;

typedef struct pci4e_s {
        s32 raw[4];     // raw 24 bit int values
        f64 enc[4];     // scaled float values rotary
        f64 lenc[4];    // scaled float values linear
        u32 setct[4];   // set offset
        f64 scale;      // scale multiplier
        u32 limit;      // modulus
        u32 zero;       // set to 1 to zero counters
        u32 dosetct;    // set to 1 to zero counters
} PCI4E;

PCI4E pci4e;

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
  __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)

#define MAP_SIZE 4096UL

#define VENDOR_ID 0x1892
#define DEVICE_ID 0x5747

off_t target;
int fd;
struct pci4e_regs *pci4e_regs;
void *virt_addr;

unsigned long read_result, writeval;
off_t target;
int access_type = 'w';

// this driver is coded to work for only one counter card.

// the pci4e does i/o through a set of 8 registers for each of 4 encoders.
// the misc register is special purpose, and is different for each encoder,
// see the manual.

// note that this driver doesn't read and write any reg structures directly,
// it just uses C to manage the addresses to be passed to readl/writel.

struct pci4e_reg {
    u32 preset;	// 0
    u32 output;	// 1
    u32 match;	// 2
    u32 control; // 3
    u32 status;	// 4
    u32 reset_channel; // 5
    u32 transfer_preset; // 6
    u32 misc;	// 7
};

#define PRESET 0
#define OUTPUT 4
#define CONTROL 12
#define RESET_CHANNEL 20

#define NENC 4

// one for each encoder
struct pci4e_regs {
	struct pci4e_reg chan[NENC];
};

static void pci4e_write(u32, u32 *);
static u32 pci4e_read(u32 *);
static void pci4e_init(void);
static void pci4e_encoder_read(void);

main() {
    s32 count;

    count = 1;

    pci4e_init();
    for (;;) {
	s32 i;

	pci4e_encoder_read();
        printf("%d:", count);
	for (i=0; i<4; i++) {
	    printf("   %d: %d", i, pci4e.raw[i]);
	}
	printf("\n");
	usleep(100*1000);
	count++;
    }
}

static void
pci4e_set_modes(void) {
    u32 i;

    pci4e.limit = 1 << 24;

    for (i=0; i<NENC; i++) {
	// see manual
	// control mode 7C000 ==>
	// 20 index will reset/preset accumulator (no)
	//
	// 19 swap a/b (controls direction of count) (no)
	// 18 enable counter (yes)
	// 16/17 modulo n counter (yes)
	//
	// 14/15 x4 mode (yes)
	pci4e_write(0x7C000, &(pci4e_regs->chan[i].control));
	pci4e_write((u32)pci4e.limit-1, &(pci4e_regs->chan[i].preset));
    }
}

static void
pci4e_init_one ()
{
    target = 0xFDD00000;
    target = 0x0;

    if((fd = open("/opt/imt/.pci4e_resource0", O_RDWR | O_SYNC)) == -1) FATAL;
    fflush(stdout);

    /* Map one page */
    pci4e_regs = (struct pci4e_regs *)mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, target);
    if(pci4e_regs == (void *) -1) FATAL;
    printf("Memory mapped at address %p.\n", pci4e_regs);
    fflush(stdout);

    pci4e_set_modes();
}

// called by main.c:do_init()

void
pci4e_init(void)
{
	pci4e_init_one();
}

static u32
pci4e_read(u32 *port)
{
	u32 val;
	val = *((unsigned long *) port);
	return val;
}

static void
pci4e_write(u32 val, u32 *port)
{
	*((unsigned long *) port) = val;
	return;
}

// called by main:cleanup_devices()
void
pci4e_close(void)
{
    if(munmap(pci4e_regs, MAP_SIZE) == -1) FATAL;
	close(fd);
	return;
}

// read one encoder port.
// chan is a channel 0-3 (corresponds to 1-4 on the card).
// raw is 24 bits of u32
// returns f64 scaled, between -limit/2 and limit/2

static f64
pci4e_read_ch(u32 i)
{
    s32 raw;
    f64 pos;

    pci4e_write(0, &pci4e_regs->chan[i].output);
    raw = pci4e_read(&pci4e_regs->chan[i].output);

    // raw (normalized) position
    pci4e.raw[i] = raw & 0xFFFFFF;
    pci4e.raw[i] <<= 8;
    pci4e.raw[i] /= 256;

    if (pci4e.limit == 0)
	pci4e.limit = 1 << 24;
    // scaled position
    // pos = (f64)raw * pci4e.scale;
    // pos = (f64)raw * 2.0 * M_PI / pci4e.limit;

    // scale pos.  if it's big, make it negative.
    pos = raw * pci4e.scale;
    if (raw > (pci4e.limit/2)) {
	pos = ((f64)raw - pci4e.limit) * pci4e.scale;
    }

    return pos; 
}

// reset the four counters to zero.
// called when you set pci4e.zero to other than 0.
// also resets the limit register to pcienc_limit.

void
pci4e_reset_all_ctrs(void)
{
    u32 i;

    for (i=0; i<NENC; i++) {
	pci4e_write(0, &pci4e_regs->chan[i].reset_channel);
    }
    pci4e_set_modes();

}

void
pci4e_encoder_read(void)
{
    u32 i;

    if (pci4e.scale < 0.00000001)
	pci4e.scale = 1.0;
    for (i=0;i<NENC;i++) {
	pci4e.enc[i] = pci4e_read_ch(i);
	// these are now identical
	pci4e.lenc[i] = pci4e.enc[i];
    }
}

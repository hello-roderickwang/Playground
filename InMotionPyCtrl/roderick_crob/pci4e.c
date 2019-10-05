// pci4e.c - US Digital PCI incremental encoder interface card
// http://www.usdigital.com/products/pci4e/
// part of the robot.o Linux Kernel Module

// InMotion2 robot system software

// Copyright 2005-2014 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

#ifdef NOTDEF
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
#endif // NOTDEF

#include "rtl_inc.h"
#include "ruser.h"
#include "robdecls.h"

static int pci4e_fd;

#define MAP_SIZE 4096UL

// this driver is coded to work for only one counter card.

// the pci4e does i/o through a set of 8 registers for each of 4 encoders.
// the misc register is special purpose, and is different for each encoder,
// see the manual.

struct pci4e_reg {
    u32 preset;                                  // 0
    u32 output;                                  // 1
    u32 match;                                   // 2
    u32 control;                                 // 3
    u32 status;                                  // 4
    u32 reset_channel;                           // 5
    u32 transfer_preset;                         // 6
    u32 misc;                                    // 7
};

#define NENC 4

// one for each encoder
struct pci4e_regs {
    struct pci4e_reg chan[NENC];
};

static struct pci4e_regs *pci4e_regs;

static s32 pci4e_regs_mapped = 0;

static void pci4e_write(u32, u32 *);
static u32 pci4e_read(u32 *);

#ifdef DEBUG
#define rob_log printf
int
main()
{
    s32 count;

    count = 1;

    pci4e_init();
    for (;;) {
        s32 i;

        pci4e_encoder_read();
        printf("%d:", count);
        for (i = 0; i < 4; i++) {
            printf("   %d: %d", i, rob->pci4e.raw[i]);
        }
        printf("\n");
        usleep(100 * 1000);
        count++;
    }
}
#endif                          // DEBUG

// check and log encoder errors
static void
pci4e_check_errs(s16 boardn, u32 i, s32 ret) {
    if (i > NENC) return;
    if (ret < 0) {
        rob->pci4e.lastret[i] = ret;
        rob->pci4e.nerrs[i]++;
    }
}

static void
pci4e_set_modes(void)
{
    u32 i;

    rob->pci4e.limit = 1 << 24;

    for (i = 0; i < NENC; i++) {
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
        pci4e_write((u32) rob->pci4e.limit - 1, &(pci4e_regs->chan[i].preset));
    }
}

// Init a single pci4e board.
// This driver will not run correctly if there is more than one board present,
// it should run properly for the last pci4e board it finds.

// In this version, we mmap the pci4e registers to the pci4e_regs struct.
// at boot time, we use udev to find the last pci4e board based on its
// vendor/device ID.  udev makes a symlink from the pci4e's resource0
// entry in sysfs to /opt/imt/.pci4e_resource0.  This makes it easy for
// our software to find.  This resource0 file is the memory at the BAR
// (base address), so pci4e_regs points to address 0x0 of the mmapped
// area.

// We don't need special capabilities (privs) to do I/O to resource0 like
// we would if we were doing I/O to /dev/mem.  (For /dev/mem, we would
// need to setcap cap_sys_rawio).

// The variable pci4e_regs_mapped tells the driver whether the I/O registers
// are mapped.  We check this to make sure we don't try to do I/O to them
// when they aren't mapped, which causes a segmentation fault.

static void
pci4e_init_one()
{
    if ((pci4e_fd = open("/opt/imt/.pci4e_resource0", O_RDWR | O_SYNC)) == -1) {
        rob_log("pci4e resource0 open failed");
        return;
    }

    /* Map one page */
    pci4e_regs =
        (struct pci4e_regs *) mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
                                   pci4e_fd, 0x0);
    if (pci4e_regs == (void *) -1) {
        rob_log("pci4e mmap failed");
	return;
    }

    pci4e_regs_mapped = 1;
    pci4e_set_modes();
}

// called by main.c:do_init()

void
pci4e_init(void)
{
    if (!rob->pci4e.have) return;

    pci4e_init_one();
}

static u32
pci4e_read(u32 *port)
{
    u32 val;
    if (!pci4e_regs_mapped) return 0;
    if (!rob->pci4e.have) return 0;
    val = *((unsigned long *) port);
    return val;
}

static void
pci4e_write(u32 val, u32 *port)
{
    if (!pci4e_regs_mapped) return;
    if (!rob->pci4e.have) return;
    *((unsigned long *) port) = val;
    return;
}

// called by main:cleanup_devices()
void
pci4e_close(void)
{
    pci4e_regs_mapped = 0;
    if (munmap(pci4e_regs, MAP_SIZE) == -1) {
        rob_log("pci4e munmap failed");
    }
    close(pci4e_fd);
    return;
}

// read one encoder port.
// chan is a channel 0-3 (corresponds to 1-4 on the card).
// raw is read as 24 bits of u32, then converted to s32
// returns f64 scaled, between -limit/2 and limit/2

static f64
pci4e_read_ch(u32 i)
{
    s32 raw;
    f64 pos;

    pci4e_write(0, &pci4e_regs->chan[i].output);
    raw = pci4e_read(&pci4e_regs->chan[i].output);

    // raw (normalized) position
    rob->pci4e.raw[i] = raw & 0xFFFFFF;
    rob->pci4e.raw[i] <<= 8;
    rob->pci4e.raw[i] /= 256;

    if (rob->pci4e.limit == 0)
        rob->pci4e.limit = 1 << 24;
    // scaled position
    // pos = (f64)raw * pci4e.scale;
    // pos = (f64)raw * 2.0 * M_PI / pci4e.limit;

    // scale pos.  if it's big, make it negative.
    pos = raw * rob->pci4e.scale;
    if (raw > (rob->pci4e.limit / 2)) {
        pos = ((f64) raw - rob->pci4e.limit) * rob->pci4e.scale;
    }

    return pos;
}

// reset the four counters to zero.
// called when you set rob->pci4e.zero to other than 0.
// also resets the limit register to pcienc_limit.

void
pci4e_reset_all_ctrs(void)
{
    u32 i;

    for (i = 0; i < NENC; i++) {
        pci4e_write(0, &pci4e_regs->chan[i].reset_channel);
    }
    pci4e_set_modes();

}

// set counters to chosen values, for calibration
// called when you set rob->pci4e.zero to other than 0.
// also resets the limit register to pcienc_limit.

void
pci4e_set_all_ctrs(void)
{
    u32 i;
    // TODO: delete struct pci4e_regs *remap;
    s16 boardn;
    u32 saved;

    boardn = 0;

    if (!rob->pci4e.have)
            return;

    for (i=0; i<NENC; i++) {
        // TODO: delete pci4e_write(0, &remap->chan[i].reset_channel);       // reset counter
        // rob->pci4e.ret[i] = PCI4E_WriteRegister(boardn, REG4E(i, RESET_CHANNEL_REGISTER), 0);
        // PCI4E_SetCount(boardn, i, rob->pci4e.setct[i]);

        saved = pci4e_read(&pci4e_regs->chan[i].preset);
        pci4e_write(rob->pci4e.setct[i], &pci4e_regs->chan[i].preset);
        pci4e_write(0, &pci4e_regs->chan[i].transfer_preset);
        pci4e_write(saved, &pci4e_regs->chan[i].preset);
        pci4e_check_errs(boardn, i, rob->pci4e.ret[i]);
    }
    // pci4e_set_modes(boardn);

}

void
pci4e_encoder_read(void)
{
    u32 i;

    if (rob->pci4e.scale < 0.00000001)
        rob->pci4e.scale = 1.0;
    for (i = 0; i < NENC; i++) {
        rob->pci4e.enc[i] = pci4e_read_ch(i);
        // these are now identical
        rob->pci4e.lenc[i] = rob->pci4e.enc[i];
    }
}

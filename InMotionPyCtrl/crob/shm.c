// InMotion2 robot system software

// Copyright 2003-2013 Interactive Motion Technologies, Inc.
// Watertown, MA, USA
// http://www.interactive-motion.com
// All rights reserved

// this program gets and sets variables in the robot's shared memory mbuffs.
// it makes a hash table of the string names, so that can be searched quickly.

// note the fancy dereference:
//
//      *((f64 *) cmds[cindex].loc)
//
// f64 is a typedef for double.
// this is the way you dereference a double whose address is stored in
// the location (void *)cmds[cindex].loc
// this is necessary to pull values out of shared memory.

// to set variables:
//  set scr 1.23
// is the same as
//  set scr 0 1.23
// you can also say
//  set scr 3 3.45
// which sets scr[3].
//
// to get variables:
//  get scr
// is the same as
//  get scr 0
//  get scr 3
// gets scr[3]
//  get scr 0 6
// gets scr[0] through scr[5].

// EXIT_FAILURE
#include <stdlib.h>

// signals
#include <signal.h>

// mbuffs
// hsearch
#include <search.h>

// primitive typedefs
#include "ruser.h"
#include "rtl_inc.h"
// robot decls
#include "robdecls.h"

// pointers to shared buffer objects
Ob *ob;
Robot *rob;
Daq *daq;
Refbuf *refbuf;

int ob_shmid;
int rob_shmid;
int daq_shmid;
int refbuf_shmid;

// number of commands in the array
u32 cmdsize;

// cmds.h gets generated by mkcmds.tcl, check it out.
#include "cmds.h"

// the ones we actually use are f64, s16, s32, u16, u32, u64.

// see cmds.h for the indices for these arrays
// sconv and gconv are printf formats, which need to be variable,
// depending on the data type.  ooh, object oriented.  (not).
// yes, this should be a c++ program, it would be infinitely less opaque.
// set, get, and array.
s8 *sconv[] = {
    "set %s %d = %s\n",
    "set %s %d = %hu\n",
    "set %s %d = %u\n",
    "set %s %d = %llu\n",
    "set %s %d = %s\n",
    "set %s %d = %hd\n",
    "set %s %d = %d\n",
    "set %s %d = %lld\n",
    "set %s %d = %f\n",
    "set %s %d = %lf\n"
};

s8 *gconv[] = {
    "get %s %d, %s\n",
    "get %s %d, %hu\n",
    "get %s %d, %u\n",
    "get %s %d, %llu\n",
    "get %s %d, %s\n",
    "get %s %d, %hd\n",
    "get %s %d, %d\n",
    "get %s %d, %lld\n",
    "get %s %d, %f\n",
    "get %s %d, %lf\n"
};

s8 *gaconv[] = {
    "get %s[%d] %d, %s\n",
    "get %s[%d] %d, %hu\n",
    "get %s[%d] %d, %u\n",
    "get %s[%d] %d, %llu\n",
    "get %s[%d] %d, %s\n",
    "get %s[%d] %d, %hd\n",
    "get %s[%d] %d, %d\n",
    "get %s[%d] %d, %lld\n",
    "get %s[%d] %d, %f\n",
    "get %s[%d] %d, %lf\n"
};

s32 gethindex(s8 *);
void do_atexit(int);

void
init(void)
{
    u32 i;
    ENTRY e, *ep;                                // for hsearch();

    // do_atexit calls mbuff_free.
    // leaving mbuffs allocated is a bad thing.
    (void) signal(1, (__sighandler_t) do_atexit);
    (void) signal(2, (__sighandler_t) do_atexit);
    (void) signal(15, (__sighandler_t) do_atexit);
    (void) atexit((void *) do_atexit);

    // allocate shared memory buffers.
    // if the first succeeds, so will the others.
    ob_shmid = shmget(OB_KEY, sizeof(Ob), 0666);
    if (ob_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory ob\n"
                "(the robot process is probably not running)\n");
        exit(EXIT_FAILURE);
    }
    ob = (Ob *) shmat(ob_shmid, NULL, 0);
    if ((s32) ob == -1) {
        fprintf(stderr, "ob shmat() failed\n");
    }
    rob_shmid = shmget(ROB_KEY, sizeof(Robot), 0666);
    if (rob_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory rob\n");
        exit(EXIT_FAILURE);
    }
    rob = (Robot *) shmat(rob_shmid, NULL, 0);
    if ((s32) rob == -1) {
        fprintf(stderr, "rob shmat() failed\n");
    }
    daq_shmid = shmget(DAQ_KEY, sizeof(Daq), 0666);
    if (daq_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory daq\n");
        exit(EXIT_FAILURE);
    }
    daq = (Daq *) shmat(daq_shmid, NULL, 0);
    if ((s32) daq == -1) {
        fprintf(stderr, "daq shmat() failed\n");
    }

    refbuf_shmid = shmget(REFBUF_KEY, sizeof(Refbuf), 0666);
    if (refbuf_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory refbuf\n");
        exit(EXIT_FAILURE);
    }
    refbuf = (Refbuf *) shmat(refbuf_shmid, NULL, 0);
    if ((s32) refbuf == -1) {
        fprintf(stderr, "refbuf shmat() failed\n");
    }
    // setcmdlocs() comes from cmds.h
    // populate an array of data item names and their mbuff locations
    setcmdlocs();

    cmdsize = (sizeof(cmds) / sizeof(cmds[0]));

    // turn the array into a hash table, so you can
    // dereference it by string name.
    //
    // it's a hash table, cmdsize would be fine,
    // but it's small, so be generous.
    (void) hcreate(cmdsize * 2);

    // insert all the data into the hash
    for (i = 0; i < cmdsize; i++) {
        // printf("ins %d %s\n", i, cmds[i].name);
        e.key = cmds[i].name;
        // e.data is really just an index, not a ptr.
        e.data = (s8 *) i;
        // it's called search, it searches for a place to insert,
        // then it inserts.  that's computer science.
        ep = hsearch(e, ENTER);
        if (ep == NULL) {
            fprintf(stderr, "hsearch insert failed: %u, %s\n", i, cmds[i].name);
            exit(EXIT_FAILURE);
        }
    }
}

void
command_loop(void)
{
    s32 i;
    u32 okset;                                   // print "ok" on successful set.

    okset = 1;

    for (;;) {
        s8 in[1024];                             // command line
        s8 out[1024];                            // printf line
        s8 cmd[1024];                            // command
        s8 cstr[1024];                           // variable name
        f64 val, val2;                           // set: index (if any), and new value (if any).
        f64 val3;                                // dummy (to catch typos)
        // get: index (if any), and count (if any).
        s32 nscan;                               // number tokens scanned by scanf
        s32 cindex;                              // command table index
        u32 aindex;                              // array index
        // u32 logindex;                // log array index

        // no prompt.  this is mostly called in scripts.
        // if we want one, we can make it optional.
        // printf("> ");

        // fflush is necessary, so answers always get flushed promptly
        // program is line-buffered when stdin is a tty,
        // but fat buffered when stdin is a pipe.
        // also good if we're prompting with no newline
        fflush(stdout);

        // read a command from stdin, parse it into 3 args.
        // val is a double, which is always sufficient.
        in[0] = 0;
        out[0] = 0;
        cmd[0] = 0;
        cstr[0] = 0;
        val = 0.0;
        val2 = 0.0;
        val3 = 0.0;
        nscan = 0;
        aindex = 0;
        cindex = 0;
        // logindex = 0;
        if (fgets(in, 1024, stdin) == NULL) {
            exit(0);
        }

        nscan = sscanf(in, "%s %s %lf %lf %lf", cmd, cstr, &val, &val2, &val3);

        switch (cmd[0]) {
        case '#':                               // comment
            break;

            // todo: hack for arrays
        case 'o':                               // okset quiet command
            okset = 0;
            break;
        case 's':                               // set name value
            cindex = gethindex(cstr);
            if (cindex >= cmdsize || cindex < 0) {
                sprintf(out, "? set command %s, index %d out of range\n", cstr, cindex);
                break;
            }
	    ob->wshm_count_accum++;
            switch (nscan) {
            case 3:                             // single var
                // e.g.: set scr 0.123
                // scalar assign
#define SASSIGN(TYPE) *((TYPE *) cmds[cindex].loc) = (TYPE) val
// sprintf (out, sconv[cmds[cindex].type], cmds[cindex].name, cindex, (TYPE)val);
                switch (cmds[cindex].type) {
                case so_s16:
                    SASSIGN(s16);
                    break;
                case so_s32:
                    SASSIGN(s32);
                    break;
                case so_u16:
                    SASSIGN(u16);
                    break;
                case so_u32:
                    SASSIGN(u32);
                    break;
                case so_u64:
                    SASSIGN(u64);
                    break;
                case so_f64:
                    SASSIGN(f64);
                    break;
                }
                break;

            case 4:                             // array deref
                // e.g.: set scr 1 0.123
                // array assign
                aindex = val;
                switch (cmds[cindex].type) {
#define AASSIGN(TYPE) ((TYPE *) cmds[cindex].loc)[aindex] = (TYPE) val2
// sprintf (out, sconv[cmds[cindex].type], cmds[cindex].name, cindex, (TYPE)val);
                case so_s16:
                    AASSIGN(s16);
                    break;
                case so_s32:
                    AASSIGN(s32);
                    break;
                case so_u16:
                    AASSIGN(u16);
                    break;
                case so_u32:
                    AASSIGN(u32);
                    break;
                case so_u64:
                    AASSIGN(u64);
                    break;
                case so_f64:
                    AASSIGN(f64);
                    break;
                }
                break;

            default:
                sprintf(out, "? wrong number of args to set\n");
                break;
            }
            // programs want set to print ok on success.
            // scripts don't want to print a string of ok's.
            if (okset)
                sprintf(out, "ok\n");
            break;

        case 'g':                               // get name
            cindex = gethindex(cstr);
            if (cindex >= cmdsize || cindex < 0) {
                sprintf(out, "? get command %s, index %d out of range\n", cstr, cindex);
                break;
            }
#define SPR(TYPE) sprintf(out, gconv[cmds[cindex].type], cmds[cindex].name, cindex, *((TYPE *) cmds[cindex].loc))
	    ob->rshm_count_accum++;
            switch (nscan) {
            case 2:                             // single var
                // e.g.: get scr
                switch (cmds[cindex].type) {
                case so_s16:
                    SPR(s16);
                    break;
                case so_s32:
                    SPR(s32);
                    break;
                case so_u16:
                    SPR(u16);
                    break;
                case so_u32:
                    SPR(u32);
                    break;
                case so_u64:
                    SPR(u64);
                    break;
                case so_f64:
                    SPR(f64);
                    break;
                }
                break;
            case 3:                             // array deref
                // e.g.: get scr 2
                aindex = val;
                if (aindex >= cmds[cindex].size) {
                    sprintf(out,
                            "? get command %s, index (%d) for %s out of range (%d)\n",
                            cstr, aindex, cmds[cindex].name, cmds[cindex].size);
                    break;
                }
                // array element printf
#define AELPR(TYPE) sprintf(out, gaconv[cmds[cindex].type], cmds[cindex].name, aindex, cindex, ((TYPE *) (cmds[cindex].loc))[aindex])
                switch (cmds[cindex].type) {
                case so_s16:
                    AELPR(s16);
                    break;
                case so_s32:
                    AELPR(s32);
                    break;
                case so_u16:
                    AELPR(u16);
                    break;
                case so_u32:
                    AELPR(u32);
                    break;
                case so_u64:
                    AELPR(u64);
                    break;
                case so_f64:
                    AELPR(f64);
                    break;
                }
                break;

            case 4:                             // array deref loop
                // e.g.: get scr 2 6
                // multi-line get, does not use out[]
                {
                    u32 i, count;
                    count = (u32) val2;

                    if (val >= cmds[cindex].size) {
                        sprintf(out, "? index (%d) for %s out of range (%d)\n",
                                (s32) val, cmds[cindex].name, cmds[cindex].size);
                        break;
                    }
                    for (i = 0; i < count; i++) {
                        aindex = val + i;
                        if (aindex >= cmds[cindex].size)
                            break;
                        // array printf
#define APR(TYPE) printf(gaconv[cmds[cindex].type], cmds[cindex].name, aindex, cindex, ((TYPE *) (cmds[cindex].loc))[aindex])
                        switch (cmds[cindex].type) {
                        case so_s16:
                            APR(s16);
                            break;
                        case so_s32:
                            APR(s32);
                            break;
                        case so_u16:
                            APR(u16);
                            break;
                        case so_u32:
                            APR(u32);
                            break;
                        case so_u64:
                            APR(u64);
                            break;
                        case so_f64:
                            APR(f64);
                            break;
                        }
                    }
                }
                break;

            default:
                sprintf(out, "? wrong number of args to get\n");
                break;
            }
            break;

        case 'a':                               // allget
            // don't use out[] for this.
            for (i = 0; i < cmdsize; i++) {
                // if there is a single arg, use it as a grep string.
                // else print them all
                if (nscan == 2 && !strstr(cmds[i].name, cstr))
                    continue;
                // the f64 here should really be a true type.
                printf(gconv[cmds[i].type], cmds[i].name, i, *((f64 *) cmds[i].loc));
            }
            printf("\n");
            break;
        case 'h':                               // help
        case '?':
            printf("set name [index] newval\n"
                   "get name [index] [count]\n"
                   "log logindex name [index]\n"
                   "allget [pattern]\n" "help\n" "quit\n\n");
            break;

        case 'q':                               // quit
            exit(0);
            break;

        default:
            // case 10: didn't work, hmmm.
            if (in[0] == 10)
                break;                           // blank line

            // no \n cuz *in already has one.
            printf("? unrecognized command: %s", in);
            break;
        }
        if (out[0]) {
            printf("%s", out);
        }
    }

}

// search for str in hash, return int index
s32
gethindex(s8 *str)
{
    ENTRY e, *ep;

    e.key = str;
    ep = hsearch(e, FIND);
    if (ep == NULL) {
        return -1;
    }
    return (s32) ep->data;
}

void
do_atexit(int sig)
{
    shmdt(ob);
    shmdt(rob);
    shmdt(daq);
    shmdt(refbuf);

    // don't call the atexit stuff atain!
    _exit(0);
}

s32
main(void)
{
    init();
    command_loop();
    return 0;
}

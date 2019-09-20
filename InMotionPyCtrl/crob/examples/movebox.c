// movebox - example progam using the shared memory api
// do a movebox

// make sure you run "go" to load control loop first!

// run make to make getpos (see ./Makefile)

// mbuffs
#include "../ruser.h"
#include "../rtl_inc.h"
// robot decls
#include "../robdecls.h"

// pointers to shared buffer objects
main()
{
    s32 ob_shmid;
    Ob *ob;

    // attech to the shared memory
    // this is like start_shm
    ob_shmid = shmget(OB_KEY, sizeof(Ob), 0666);
    ob = (Ob *) shmat(ob_shmid, NULL, 0);

    // allow the robot to move.
    // this is like start_loop
    ob->paused = 0;
    ob->slot_max = 2;

    // set up a movebox-style slot
    // to move the robot 10 cm,
    // from (0,0) to (.1,0)
    ob->copy_slot.id = 0;
    ob->copy_slot.fnid = 0;

    ob->copy_slot.i = 0;
    ob->copy_slot.term = 200;
    ob->copy_slot.incr = 1;

    ob->copy_slot.b0.point.x = 0.0;
    ob->copy_slot.b0.point.y = 0.0;
    ob->copy_slot.b0.w = 0.0;
    ob->copy_slot.b0.h = 0.0;

    ob->copy_slot.b1.point.x = 0.1;
    ob->copy_slot.b1.point.y = 0.0;
    ob->copy_slot.b1.w = 0.0;
    ob->copy_slot.b1.h = 0.0;

    // tell the system to run the slot
    ob->copy_slot.running = 1;
    ob->copy_slot.go = 1;

    // release the shared memory
    shmdt(ob);
}

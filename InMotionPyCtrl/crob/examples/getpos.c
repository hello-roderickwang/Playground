// getpos - example progam using the shared memory api
// to retrieve position and velocity from the control loop

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

    ob_shmid = shmget(OB_KEY, sizeof(Ob), 0666);
    ob = (Ob *) shmat(ob_shmid, NULL, 0);
    printf("x = %f, y = %f, vx = %f, vy = %f\n",
           ob->pos.x, ob->pos.y, ob->vel.x, ob->vel.y);
    shmdt(ob);
}

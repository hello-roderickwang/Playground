// atinetft.c - read from an ATI force tranducer and put values in shm

// modified from ATI example software

// InMotion2 robot system software

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#define HOST "atinetft"
#define PORT 49152                               // Port the Net F/T always uses
#define STARTCOMMAND 2                           // Command code 2 starts streaming
#define STOPCOMMAND 0                            // Command code 0 stops streaming
#define NUM_SAMPLES 0                            // Will stream data until stopped

// Typedefs used so integer sizes are more explicit
typedef unsigned int uint32;
typedef int int32;
typedef unsigned short uint16;
typedef short int16;
typedef unsigned char byte;

// IMT shared memory stuff
#include "ruser.h"
#include "rtl_inc.h"
#include "robdecls.h"
Ob *ob;
Robot *rob;
int rob_shmid;
int ob_shmid;
int ret, fttick;

int socketHandle;                                // Handle to UDP socket used to communicate with Net F/T.
struct sockaddr_in addr;                         // Address of Net F/T.
struct hostent *he;                              // Host entry for Net F/T.
byte request[8];                                 // The request data sent to the Net F/T.
byte response[36];                               // The raw response data received from the Net F/T.
int i;                                           // Generic loop/array index.
int err;                                         // Error status of operations.
double cpf;                                      // counts per force
double cpt;                                      // counts per torque

struct timeval timeout;				 // timeout on receive

void
cleanup_signal(int sig)
{
    // stop FT stream and exit
    *(uint16 *) & request[2] = htons(STOPCOMMAND);      // per table 9.1 in Net F/T user manual.
    send(socketHandle, request, 8, 0);
    shmdt(ob);
    shmdt(rob);
    exit(0);
}

int
main(int argc, char **argv)
{

    if (argc < 3) {
        fprintf(stderr, "Usage: %s counts_per_force counts_per_torque\n", argv[0]);
        return 1;
    }

    cpf = atof(argv[1]);
    cpt = atof(argv[2]);

    if (cpf == 0 || cpt == 0) {
        fprintf(stderr, "Counts per force and counts per torque must not be zero.\n");
        return 1;
    }

    // Calculate number of samples, command code, and open socket here.
    socketHandle = socket(AF_INET, SOCK_DGRAM, 0);
    if (socketHandle == -1) {
        exit(errno);
    }

    timeout.tv_sec = 0;
    timeout.tv_usec = 1100;	// 110% of the 1000 Hz packet stream rate
    if (setsockopt(socketHandle, SOL_SOCKET, SO_RCVTIMEO, (char *) &timeout, sizeof(timeout)) < 0) {
        printf("setsockopt failed\n");
        exit(errno);
    }

    // install signal handler
    signal(SIGTERM, cleanup_signal);
    signal(SIGINT, cleanup_signal);
    signal(SIGHUP, cleanup_signal);

    he = gethostbyname(HOST);
    memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);

    err = connect(socketHandle, (struct sockaddr *) &addr, sizeof(addr));
    if (err < 0) {
        exit(errno);
    }
    // now we have set up the socket

    // get Robot shared memory
    rob_shmid = shmget(ROB_KEY, sizeof(Robot), 0666);
    if (rob_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory rob\n");
        exit(errno);
    }
    rob = (Robot *) shmat(rob_shmid, NULL, 0);
    if ((s32) rob == -1) {
        fprintf(stderr, "rob shmat() failed\n");
        exit(errno);
    }
    // get Ob shared memory
    ob_shmid = shmget(OB_KEY, sizeof(Ob), 0666);
    if (ob_shmid == -1) {
        fprintf(stderr, "could not shmget() access to shared memory ob\n");
        exit(errno);
    }
    ob = (Ob *) shmat(ob_shmid, NULL, 0);
    if ((s32) ob == -1) {
        fprintf(stderr, "ob shmat() failed\n");
        exit(errno);
    }

    *(uint16 *) & request[0] = htons(0x1234);    // standard header.
    *(uint16 *) & request[2] = htons(STARTCOMMAND);     // per table 9.1 in Net F/T user manual.
    *(uint32 *) & request[4] = htonl(NUM_SAMPLES);      // see section 9.1 in Net F/T user manual.
    send(socketHandle, request, 8, 0);

    daemon(0, 0);

    for (;;) {
        // Receiving the response.
        ret = recv(socketHandle, response, 36, 0);
        if (ret < 0) {
            continue;
        }
        rob->ft.status = (uint32) ntohl(*(uint32 *) & response[8]);
        for (i = 0; i < 6; i++) {
            // casting through a mess of types. don't change this without testing.
            rob->ft.raw[i] = (int32) ntohl(*(int32 *) & response[12 + i * 4])
                / ((i <= 3) ? cpf : cpt);
        }
    }
    return 0;
}

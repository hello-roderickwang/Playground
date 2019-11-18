//
// Created by roderick on 11/11/19.
//

#include <stdio.h>

#define SIGNAL_MAX 100

FILE *fp;
int status;
char signals[SIGNAL_MAX];
int sig;

char communicate(void){
    fp = popen("python simple_output.py", "r");
    if (fp == NULL){
        printf("popen FAILED!\n");
    }
    while (fgets(signals, SIGNAL_MAX, fp) != NULL){
        printf("popen SUCCESS!\n");
        printf("signals in communicator: %s\n", signals);
        printf("signals in communicator[0]: %c\n", signals[0]);
        sig = (int)signals[0] - 48;
//        return signals;
    }
//    int i;
//    for (i=0; i<100; i++){
//        printf("signal[%d]: %c\n", i, signals[i]);
//    }
    status = pclose(fp);
    if (status == -1){
        printf("pclose FAILED!\n");
    }else{
        printf("pclose SUCCESS!\n");
    }
    printf("sig in communicator: %d\n", sig);
    return sig;
}
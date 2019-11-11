//
// Created by roderick on 11/11/19.
//

#include "communicator.c"

int main(void){
    int signal;
    signal = communicate();
    printf("signal from communicator: %d\n", signal);
    return 0;
}
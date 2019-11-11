#include "subprocess.c"
#include <stdio.h>

int main(void){
    int a;
    a = exec("python simple_output.py");
    printf("This is a from python file: %d", a);
}

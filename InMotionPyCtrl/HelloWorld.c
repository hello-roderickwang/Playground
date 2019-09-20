// @Date    : 2019-09-19 16:14:40
// @Author  : Xuenan(Roderick) Wang
// @Email   : roderick_wang@outlook.com
// @GitHub  : https://github.com/hello-roderickwang

#include <stdio.h>
int main(int argc, char* argv){
    int varA = argv[1];
    int varB = argv[2];
    printf("Enter Var_A:");
    scanf("%d", &varA);
    printf("\nEnter Var_B:");
    scanf("%d", &varB);
    printf("varA:%d, varB:%d\n", varA, varB);
    printf("argc:%d\n", argc);
    printf("argv[1]:%d, argv[2]:%d\n", argv[1], argv[2]);
    if(varA == 1){
        printf("Hello World!\n");
    }
    else{
        printf("WRONG!\n");
    }
    if(varB == 2){
        printf("Hello World Again!\n");
    }
    else{
        printf("WRONG AGAIN!\n");
    }
    return 3;
}

#include <stdio.h>

#define PATH_MAX 100 

FILE *fp;
int status;
char path[PATH_MAX];

int main(void)
{
fp = popen("python simple_output.py", "r");
if (fp == NULL)
{
    printf("popen SUCCESS!\n");
}

while(fgets(path, PATH_MAX, fp) != NULL)
    printf("%s", path);

status = pclose(fp);
if (status == -1)
{
    printf("pclose ERROR!\n");
}
else
{
    printf("pclose SUCCESS!\n");
}
return 0;
}

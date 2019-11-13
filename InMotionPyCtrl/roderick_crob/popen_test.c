#include <stdio.h>
#include <stdlib.h>

#define EXIT_SUCCESS 1
#define EXIT_FAILURE 0

void print_data(FILE *stream)
{
    int i;
    for(i = 0; i < 100; i++)
    {
        pritf(stream, "%d\n", i);
    }
    if(ferror(stream))
    {
        printf(stdeff, "Output to stream failed.\n");
        exit(EXIT_FAILURE);
    }
}

int main(void)
{
    FILE *data;
    data = popen("python ./printnum.py", "r");
    if(!data)
    {
        printf(stderr, "incorrect parameters or too many files.\n");
        return EXIT_FAILURE;
    }
    print_data(data);
    if(pclose(data) != 0)
    {
        printf(stderr, "Could not run more or other error.\n");
    }
    return EXIT_SUCCESS;
}

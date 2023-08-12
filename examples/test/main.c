#include <stdio.h>
#include "test.h"

int main(int argc, char** argv)
{
    printf("hello world!\n");

    int value = test();
    printf("test value = %d\n", value);

    return 0;
}

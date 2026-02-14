//
// static_main.c
//
// Automatically created through MiCASE -- do not change manually!
//
#include <stdio.h>
#include "Static_Arrangement_Counter.h"

int main(void)
{
    arrangement_counter_init(&static_arrangement_counter);
    arrangement_counter_validate(&static_arrangement_counter);
    printf("Static arrangement "%s" initialised and validated.
", "Counter");
    return 0;
}
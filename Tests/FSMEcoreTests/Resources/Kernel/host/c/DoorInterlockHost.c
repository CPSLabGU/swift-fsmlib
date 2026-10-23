// Host implementation of the functions that DoorInterlock declares.
#include <stdbool.h>
#include <stdio.h>

bool isSafe(bool closed);
void logEvent(int event);

bool isSafe(bool closed)
{
    return closed;
}

void logEvent(int event)
{
    printf("log %d\n", event);
}

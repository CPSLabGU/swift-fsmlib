// Host implementation of the functions that DoorInterlock declares.
#include <iostream>

bool isSafe(bool closed);
void logEvent(int event);

bool isSafe(bool closed)
{
    return closed;
}

void logEvent(int event)
{
    std::cout << "log " << event << '\n';
}

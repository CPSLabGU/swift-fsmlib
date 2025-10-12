#include <stdio.h>
#include <time.h>
#include "Machine_Common.h"
#include "Static_Arrangement_Counter.h"

#define at(t) (time(&machine->now) > machine->start + (t))

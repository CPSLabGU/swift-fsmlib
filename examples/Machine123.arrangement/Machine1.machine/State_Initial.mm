//
// State_Initial.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine1_Includes.h"
#include "Machine1.h"
#include "State_Initial.h"

#include "State_Initial_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMMachine1;
using namespace State;

Initial::Initial(const char *name): CLState(name, *new Initial::OnEntry, *new Initial::OnExit, *new Initial::Internal, NULLPTR, new Initial::OnSuspend, new Initial::OnResume)
{
}

Initial::~Initial()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

}

void Initial::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine1_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "Machine1_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnEntry.mm"
}

void Initial::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine1_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "Machine1_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnExit.mm"
}

void Initial::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine1_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "Machine1_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_Internal.mm"
}

void Initial::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine1_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "Machine1_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnSuspend.mm"
}

void Initial::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine1_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "Machine1_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnResume.mm"
}

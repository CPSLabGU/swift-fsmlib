//
// State_InitialPseudoState.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Counter_Includes.h"
#include "Counter.h"
#include "State_InitialPseudoState.h"

#include "State_InitialPseudoState_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMCounter;
using namespace State;

InitialPseudoState::InitialPseudoState(const char *name): CLState(name, *new InitialPseudoState::OnEntry, *new InitialPseudoState::OnExit, *new InitialPseudoState::Internal, NULLPTR, new InitialPseudoState::OnSuspend, new InitialPseudoState::OnResume)
{
	_transitions[0] = new Transition_0();
}

InitialPseudoState::~InitialPseudoState()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

	delete _transitions[0];
}

void InitialPseudoState::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"
#	include "State_InitialPseudoState_OnEntry.mm"
}

void InitialPseudoState::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"
#	include "State_InitialPseudoState_OnExit.mm"
}

void InitialPseudoState::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"
#	include "State_InitialPseudoState_Internal.mm"
}

void InitialPseudoState::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"
#	include "State_InitialPseudoState_OnSuspend.mm"
}

void InitialPseudoState::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"
#	include "State_InitialPseudoState_OnResume.mm"
}

bool InitialPseudoState::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_InitialPseudoState_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_InitialPseudoState_FuncRefs.mm"

	return
	(
#		include "State_InitialPseudoState_Transition_0.expr"
	);
}

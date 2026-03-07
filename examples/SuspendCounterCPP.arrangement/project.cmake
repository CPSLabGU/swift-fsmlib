# Sources for the SuspendCounterCPP Objective-C++ FSM arrangement.
set(SuspendCounterCPP_ARRANGEMENT_SOURCES
    Arrangement_SuspendCounterCPP.mm
    Static_Arrangement_SuspendCounterCPP.mm
)

# Infrastructure sources for the FSM C++ runtime.
set(INFRASTRUCTURE_SOURCES
    infrastructure/StateMachineVector.cc
    infrastructure/SuspensibleMachine.cc
)

# Include directories for building SuspendCounterCPP.
set(SuspendCounterCPP_ARRANGEMENT_INCDIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/infrastructure>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SuspendCounterCPP.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SuspendCounterCPP.machine>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CounterCPP.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CounterCPP.machine>
)

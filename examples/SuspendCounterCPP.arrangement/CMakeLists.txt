cmake_minimum_required(VERSION 3.21)

project(SuspendCounterCPP_arrangement CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

# Set the default build type to Debug.
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Debug)
endif()

# Define FSM_SUPPORT_SUSPEND for suspensible machines
add_definitions(-DFSM_SUPPORT_SUSPEND)

include(project.cmake)

add_subdirectory(SuspendCounterCPP.machine)
add_subdirectory(CounterCPP.machine)
add_executable(run_SuspendCounterCPP_arrangement static_main.cc ${SuspendCounterCPP_ARRANGEMENT_SOURCES} ${INFRASTRUCTURE_SOURCES})
target_include_directories(run_SuspendCounterCPP_arrangement PRIVATE
  ${SuspendCounterCPP_ARRANGEMENT_INCDIRS}
)
target_link_libraries(run_SuspendCounterCPP_arrangement
    SuspendCounterCPP_fsm
    CounterCPP_fsm
)

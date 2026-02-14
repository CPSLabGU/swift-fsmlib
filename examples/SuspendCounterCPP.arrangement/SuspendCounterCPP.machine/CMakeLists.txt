cmake_minimum_required(VERSION 3.21)

project(SuspendCounterCPP CXX)

# Require the C++ standard to be C++17,
# but allow extensions.
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

add_library(SuspendCounterCPP_fsm STATIC ${SuspendCounterCPP_FSM_SOURCES})
target_include_directories(SuspendCounterCPP_fsm PRIVATE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/infrastructure>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<INSTALL_INTERFACE:include/fsms/SuspendCounterCPP.machine>
  $<INSTALL_INTERFACE:fsms/SuspendCounterCPP.machine>
  $GUNAO_DIR/Common
  $GUNAO_DIR/posix/gusimplewhiteboard
  $GUNAO_DIR/posix/gufsm/clfsm
  $GUNAO_DIR/posix/gufsm/clfsm
  $GUNAO_DIR/posix/gufsm
  $HOME/src/MiPal/GUNao/Common
  $HOME/src/MiPal/GUNao/posix/gusimplewhiteboard
  $HOME/src/MiPal/GUNao/posix/gufsm/clfsm
  $HOME/src/MiPal/GUNao/posix/gufsm
  $MACHINE_DIR
  $MACHINE_DIR/${BUILD_SUBDIR}
  .
  ..
)

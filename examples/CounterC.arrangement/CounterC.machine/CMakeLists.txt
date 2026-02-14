cmake_minimum_required(VERSION 3.21)

project(CounterC C)

# Require the C standard to be C17,
# but allow extensions.
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

# Set the default build type to Debug.
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Debug)
endif()

include(project.cmake)

add_library(CounterC_fsm STATIC ${CounterC_FSM_SOURCES})
target_include_directories(CounterC_fsm PRIVATE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<INSTALL_INTERFACE:include/fsms/CounterC.machine>
  $<INSTALL_INTERFACE:fsms/CounterC.machine>
  "$GUNAO_DIR/Common"
  "$GUNAO_DIR/posix/gusimplewhiteboard"
  "$GUNAO_DIR/posix/gufsm/clfsm"
  "$GUNAO_DIR/posix/gufsm/clfsm"
  "$GUNAO_DIR/posix/gufsm"
  "$HOME/src/MiPal/GUNao/Common"
  "$HOME/src/MiPal/GUNao/posix/gusimplewhiteboard"
  "$HOME/src/MiPal/GUNao/posix/gufsm/clfsm"
  "$HOME/src/MiPal/GUNao/posix/gufsm"
  "$MACHINE_DIR"
  "$MACHINE_DIR/${BUILD_SUBDIR}"
  "."
  ".."
)

# Sources for the CounterC LLFSM arrangement.
set(CounterC_ARRANGEMENT_SOURCES
    Arrangement_CounterC.c
    Machine_Common.c
)

# Static arrangement of machines for CounterC.
set(CounterC_STATIC_ARRANGEMENT_SOURCES
    Static_Arrangement_CounterC.c
)

# Include directories for building CounterC.
set(CounterC_ARRANGEMENT_INCDIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CounterC.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CounterC.machine>
)

# Subdirectories for building CounterC.
set(CounterC_ARRANGEMENT_SUBDIRS
    "CounterC.machine"
)

# Build directories for CounterC.
set(CounterC_ARRANGEMENT_BUILD_DIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CounterC.machine>
)

# Installed include directories for CounterC.
set(CounterC_ARRANGEMENT_INSTALL_INCDIRS
  $<INSTALL_INTERFACE:include/fsms/CounterC.arrangement> 
  $<INSTALL_INTERFACE:fsms/CounterC.arrangement> 
  $<INSTALL_INTERFACE:include/fsms/CounterC.arrangement/CounterC.machine>
  $<INSTALL_INTERFACE:fsms/CounterC.arrangement/CounterC.machine>
)

include(${CMAKE_CURRENT_LIST_DIR}/CounterC.machine/project.cmake)
foreach(src ${CounterC_FSM_SOURCES})
  list(APPEND CounterC_ARRANGEMENT_FSMS "CounterC")
  list(APPEND CounterC_ARRANGEMENT_FSM_CounterC_SOURCES CounterC.machine/${src})
  list(APPEND CounterC_ARRANGEMENT_SOURCES CounterC.machine/${src})
endforeach()

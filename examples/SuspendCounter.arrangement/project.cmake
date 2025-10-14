# Sources for the SuspendCounter LLFSM arrangement.
set(SuspendCounter_ARRANGEMENT_SOURCES
    Arrangement_SuspendCounter.c
    Machine_Common.c
)

# Static arrangement of machines for SuspendCounter.
set(SuspendCounter_STATIC_ARRANGEMENT_SOURCES
    Static_Arrangement_SuspendCounter.c
)

# Include directories for building SuspendCounter.
set(SuspendCounter_ARRANGEMENT_INCDIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SuspendCounter.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SuspendCounter.machine>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine>
)

# Subdirectories for building SuspendCounter.
set(SuspendCounter_ARRANGEMENT_SUBDIRS
    "SuspendCounter.machine"
    "Counter.machine"
)

# Build directories for SuspendCounter.
set(SuspendCounter_ARRANGEMENT_BUILD_DIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SuspendCounter.machine>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine>
)

# Installed include directories for SuspendCounter.
set(SuspendCounter_ARRANGEMENT_INSTALL_INCDIRS
  $<INSTALL_INTERFACE:include/fsms/SuspendCounter.arrangement> 
  $<INSTALL_INTERFACE:fsms/SuspendCounter.arrangement> 
  $<INSTALL_INTERFACE:include/fsms/SuspendCounter.arrangement/SuspendCounter.machine>
  $<INSTALL_INTERFACE:fsms/SuspendCounter.arrangement/SuspendCounter.machine>
  $<INSTALL_INTERFACE:include/fsms/SuspendCounter.arrangement/Counter.machine>
  $<INSTALL_INTERFACE:fsms/SuspendCounter.arrangement/Counter.machine>
)

include(${CMAKE_CURRENT_LIST_DIR}/SuspendCounter.machine/project.cmake)
foreach(src ${SuspendCounter_FSM_SOURCES})
  list(APPEND SuspendCounter_ARRANGEMENT_FSMS "SuspendCounter")
  list(APPEND SuspendCounter_ARRANGEMENT_FSM_SuspendCounter_SOURCES SuspendCounter.machine/${src})
  list(APPEND SuspendCounter_ARRANGEMENT_SOURCES SuspendCounter.machine/${src})
endforeach()
include(${CMAKE_CURRENT_LIST_DIR}/Counter.machine/project.cmake)
foreach(src ${Counter_FSM_SOURCES})
  list(APPEND SuspendCounter_ARRANGEMENT_FSMS "Counter")
  list(APPEND SuspendCounter_ARRANGEMENT_FSM_Counter_SOURCES Counter.machine/${src})
  list(APPEND SuspendCounter_ARRANGEMENT_SOURCES Counter.machine/${src})
endforeach()
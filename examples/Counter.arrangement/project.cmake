# Sources for the Counter LLFSM arrangement.
set(Counter_ARRANGEMENT_SOURCES
    Arrangement_Counter.c
    Machine_Common.c
)

# Static arrangement of machines for Counter.
set(Counter_STATIC_ARRANGEMENT_SOURCES
    Static_Arrangement_Counter.c
)

# Include directories for building Counter.
set(Counter_ARRANGEMENT_INCDIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine>
)

# Subdirectories for building Counter.
set(Counter_ARRANGEMENT_SUBDIRS
    "Counter.machine"
)

# Build directories for Counter.
set(Counter_ARRANGEMENT_BUILD_DIRS
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Counter.machine>
)

# Installed include directories for Counter.
set(Counter_ARRANGEMENT_INSTALL_INCDIRS
  $<INSTALL_INTERFACE:include/fsms/Counter.arrangement> 
  $<INSTALL_INTERFACE:fsms/Counter.arrangement> 
  $<INSTALL_INTERFACE:include/fsms/Counter.arrangement/Counter.machine>
  $<INSTALL_INTERFACE:fsms/Counter.arrangement/Counter.machine>
)

include(${CMAKE_CURRENT_LIST_DIR}/Counter.machine/project.cmake)
foreach(src ${Counter_FSM_SOURCES})
  list(APPEND Counter_ARRANGEMENT_FSMS "Counter")
  list(APPEND Counter_ARRANGEMENT_FSM_Counter_SOURCES Counter.machine/${src})
  list(APPEND Counter_ARRANGEMENT_SOURCES Counter.machine/${src})
endforeach()
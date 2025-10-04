cmake_minimum_required(VERSION 3.21)

project(SuspendCounter C)

include(project.cmake)

add_library(SuspendCounter_arrangement STATIC ${SuspendCounter_ARRANGEMENT_SOURCES})
add_library(SuspendCounter_static_arrangement STATIC ${SuspendCounter_STATIC_ARRANGEMENT_SOURCES})

target_include_directories(SuspendCounter_arrangement PRIVATE 
  ${SuspendCounter_ARRANGEMENT_INCDIRS}
  ${SuspendCounter_ARRANGEMENT_INSTALL_INCDIRS}
)
target_include_directories(SuspendCounter_static_arrangement PRIVATE
  ${SuspendCounter_ARRANGEMENT_INCDIRS}
  ${SuspendCounter_ARRANGEMENT_INSTALL_INCDIRS}
)

add_executable(run_SuspendCounter_arrangement static_main.c)

target_include_directories(run_SuspendCounter_arrangement PRIVATE
  ${SuspendCounter_ARRANGEMENT_INCDIRS}
  ${SuspendCounter_ARRANGEMENT_INSTALL_INCDIRS}
)
add_subdirectory(Suspend.machine)
add_subdirectory(Counter.machine)
target_link_libraries(run_SuspendCounter_arrangement
    SuspendCounter_static_arrangement
    SuspendCounter_arrangement
    Suspend_fsm
    Counter_fsm
)

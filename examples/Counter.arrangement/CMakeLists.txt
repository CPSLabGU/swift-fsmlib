cmake_minimum_required(VERSION 3.21)

project(Counter C)

include(project.cmake)

add_library(Counter_arrangement STATIC ${Counter_ARRANGEMENT_SOURCES})
add_library(Counter_static_arrangement STATIC ${Counter_STATIC_ARRANGEMENT_SOURCES})

target_include_directories(Counter_arrangement PRIVATE 
  ${Counter_ARRANGEMENT_INCDIRS}
  ${Counter_ARRANGEMENT_INSTALL_INCDIRS}
)
target_include_directories(Counter_static_arrangement PRIVATE
  ${Counter_ARRANGEMENT_INCDIRS}
  ${Counter_ARRANGEMENT_INSTALL_INCDIRS}
)

add_executable(run_Counter_arrangement static_main.c)

target_include_directories(run_Counter_arrangement PRIVATE
  ${Counter_ARRANGEMENT_INCDIRS}
  ${Counter_ARRANGEMENT_INSTALL_INCDIRS}
)
add_subdirectory(Counter.machine)
target_link_libraries(run_Counter_arrangement
    Counter_static_arrangement
    Counter_arrangement
    Counter_fsm
)

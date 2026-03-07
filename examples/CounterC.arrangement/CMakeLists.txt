cmake_minimum_required(VERSION 3.21)

project(CounterC C)

include(project.cmake)

add_library(CounterC_arrangement STATIC ${CounterC_ARRANGEMENT_SOURCES})
add_library(CounterC_static_arrangement STATIC ${CounterC_STATIC_ARRANGEMENT_SOURCES})

target_include_directories(CounterC_arrangement PRIVATE 
  ${CounterC_ARRANGEMENT_INCDIRS}
  ${CounterC_ARRANGEMENT_INSTALL_INCDIRS}
)
target_include_directories(CounterC_static_arrangement PRIVATE
  ${CounterC_ARRANGEMENT_INCDIRS}
  ${CounterC_ARRANGEMENT_INSTALL_INCDIRS}
)

add_executable(run_CounterC_arrangement static_main.c)

target_include_directories(run_CounterC_arrangement PRIVATE
  ${CounterC_ARRANGEMENT_INCDIRS}
  ${CounterC_ARRANGEMENT_INSTALL_INCDIRS}
)
add_subdirectory(CounterC.machine)
target_link_libraries(run_CounterC_arrangement
    CounterC_static_arrangement
    CounterC_arrangement
    CounterC_fsm
)

cmake_minimum_required(VERSION 3.13.1)

# Register custom boards located in <project_root>/boards/
list(APPEND BOARD_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/..)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(zephyr_nrf52840_project)
target_sources(app PRIVATE src/main.c)


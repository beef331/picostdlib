cmake_minimum_required(VERSION 3.13...3.27)

# initialize pico-sdk from GIT
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_FETCH_FROM_GIT on)

# pico_sdk_import.cmake is a single file copied from this SDK
# note: this must happen before project()
include(pico_sdk_import.cmake)

project(tinyusb)
# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

set(Imports imports.cmake)

if(EXISTS "../${Imports}")

# add program file(s)
file(GLOB NimSources build/nimcache/*.c)

# Suppress gcc warnings for nim-generated files
set_source_files_properties(${NimSources} PROPERTIES COMPILE_OPTIONS "-w")

# Add Nim-generated files AND the usb_descriptors.c file to the build
add_executable(tinyusb ${NimSources} ${CMAKE_CURRENT_LIST_DIR}/../src/usb_descriptors.c)

# Make sure TinyUSB can find tusb_config.h
target_include_directories(tinyusb PUBLIC ${CMAKE_CURRENT_LIST_DIR}/../src)

# Add directory containing this CMakeLists file to include search path.
# This is required so that the nimbase.h file is found. Other headers
# required for a project can also be placed here.
target_include_directories(tinyusb PUBLIC ${CMAKE_CURRENT_LIST_DIR})

include(${Imports}) # Include our generated file
link_imported_libs(tinyusb) # call our generated function to import all libs we're using

# Link tinyusb device libs
target_link_libraries(tinyusb tinyusb_device tinyusb_board)

# Note: since we create a custom tinyusb device, USB stdio must be disabled
pico_enable_stdio_usb(tinyusb 0)
pico_enable_stdio_uart(tinyusb 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(tinyusb)

# add url via pico_set_program_url
pico_set_program_url(tinyusb 1)
endif()

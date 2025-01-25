cmake_minimum_required(VERSION 3.13...3.27)

if(NOT DEFINED OUTPUT_NAME)
  set(OUTPUT_NAME blink)
endif()

# Set CMake build type. Debug, Release, MinSizeRel, RelWithDebInfo
set(CMAKE_BUILD_TYPE Debug)

# Set standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initialize pico-sdk from GIT
# (note this can come from environment, CMake cache etc)
# set(PICO_SDK_FETCH_FROM_GIT on)
# set(PICO_SDK_PATH ENV{PICO_SDK_PATH})

# Set board type here
if(NOT DEFINED PICO_BOARD)
  set(PICO_BOARD pico)
endif()

# Support C++ exceptions with Nim
set(PICO_CXX_ENABLE_EXCEPTIONS 1)

# Uncomment to disable picotool binary info
# set(PICO_NO_BINARY_INFO 1)

execute_process(
  COMMAND nimble path picostdlib
  OUTPUT_VARIABLE PICOSTDLIB_DIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(pico_generate_pio_header_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

# note: this must happen before project()
include(${PICOSTDLIB_DIR}/picostdlib/cmake/pico_sdk_import.cmake)

project(${OUTPUT_NAME} C CXX ASM)


include(FetchContent)

FetchContent_Declare(mbedtls
  GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
  GIT_TAG        v2.28.8
)

FetchContent_Declare(lwip
  GIT_REPOSITORY https://git.savannah.gnu.org/git/lwip.git
  GIT_TAG        STABLE-2_2_0_RELEASE
)

FetchContent_Declare(freertos_kernel
  GIT_REPOSITORY https://github.com/FreeRTOS/FreeRTOS-Kernel.git
  GIT_TAG        V11.1.0
)

# fetch and use alternative mbedtls version
#FetchContent_MakeAvailable(mbedtls)
#set(PICO_MBEDTLS_PATH ${mbedtls_SOURCE_DIR})

# fetch and use alternative lwip version
#FetchContent_MakeAvailable(lwip)
#set(PICO_LWIP_PATH ${lwip_SOURCE_DIR})

# fetch and initialize FreeRTOS-Kernel
#add_library(freertos_config INTERFACE)
#target_include_directories(freertos_config SYSTEM INTERFACE ${CMAKE_SOURCE_DIR}/csource) # The config file directory
#set(FREERTOS_PORT GCC_RP2040 CACHE STRING "")
#FetchContent_MakeAvailable(freertos_kernel)
#include(${freertos_kernel_SOURCE_DIR}/portable/ThirdParty/GCC/RP2040/FreeRTOS_Kernel_import.cmake)


# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

include(${PICOSTDLIB_DIR}/picostdlib/cmake/picostdlib.cmake)

# add executables below, either directly or with include/add_subdirectory

add_executable(${OUTPUT_NAME})

picostdlib_target(${OUTPUT_NAME} ${OUTPUT_NAME})

# set_target_properties(${OUTPUT_NAME} PROPERTIES LINKER_LANGUAGE CXX)

target_include_directories(${OUTPUT_NAME} PRIVATE
  ${CMAKE_SOURCE_DIR}/csource
)

target_link_libraries(${OUTPUT_NAME}
  # Additional libraries
)

target_compile_definitions(${OUTPUT_NAME} PRIVATE
  # CYW43_HOST_NAME="PicoW"
  PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS=2000
)

# enable usb output, disable uart output
pico_enable_stdio_usb(${OUTPUT_NAME} 1)
pico_enable_stdio_uart(${OUTPUT_NAME} 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(${OUTPUT_NAME})

# add url via pico_set_program_url
# pico_set_program_url(${OUTPUT_NAME} "")

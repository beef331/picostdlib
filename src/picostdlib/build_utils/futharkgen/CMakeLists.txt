cmake_minimum_required(VERSION 3.13...3.27)

# Set CMake build type. Debug, Release, MinSizeRel, RelWithDebInfo
set(CMAKE_BUILD_TYPE Release)

# Set standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initialize pico-sdk from GIT
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_FETCH_FROM_GIT on)
#set(PICO_SDK_PATH ENV{PICO_SDK_PATH}) # Set by piconim

# Set board type here
if(NOT DEFINED PICO_BOARD)
  set(PICO_BOARD pico)
endif()

# Support C++ exceptions with Nim
set(PICO_CXX_ENABLE_EXCEPTIONS 1)

# Uncomment to disable picotool binary info
# set(PICO_NO_BINARY_INFO 1)


set(PICOSTDLIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
set(pico_generate_pio_header_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

# note: this must happen before project()
include(${PICOSTDLIB_DIR}/picostdlib/cmake/pico_sdk_import.cmake)

project(futharkgen C CXX ASM)


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
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE ${CMAKE_SOURCE_DIR}/../template/csource) # The config file directory
set(FREERTOS_PORT GCC_ARM_CM0 CACHE STRING "")
# FetchContent_MakeAvailable(freertos_kernel)
# include(${freertos_kernel_SOURCE_DIR}/portable/ThirdParty/GCC/RP2040/FreeRTOS_Kernel_import.cmake)


# initialize the Raspberry Pi Pico SDK
pico_sdk_init()


include(${PICOSTDLIB_DIR}/picostdlib/cmake/picostdlib.cmake)

cmake_minimum_required(VERSION 3.13...3.27)

# initialize the SDK based on PICO_SDK_PATH

# note: this must happen before project()
include(pico_sdk_import.cmake)

project(ws2812_pio)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# add program file(s)
file(GLOB MyCSources *.c)
add_executable(ws2812_pio ${MyCSources})

pico_generate_pio_header(ws2812_pio ${CMAKE_CURRENT_LIST_DIR}/../src/ws2812.pio)

# pull in our pico_stdlib which pulls in commonly used features
# hardware_adc tinyusb_device tinyusb_board Currently supported.
target_link_libraries(ws2812_pio pico_stdlib hardware_pio)

# enable usb output, disable uart output
pico_enable_stdio_usb(ws2812_pio 1)
pico_enable_stdio_uart(ws2812_pio 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(ws2812_pio)

# add url via pico_set_program_url
pico_set_program_url(ws2812_pio 1)

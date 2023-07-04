# Package

version       = "0.4.0"  # Don't forget to update version in piconim.nim (if needed)
author        = "The piconim contributors"
description   = "Nim bindings for the Raspberry Pi Pico SDK"
license       = "BSD-3-Clause"
srcDir        = "src"
backend       = "c"
bin           = @["picostdlib/build_utils/piconim"]
installExt    = @["nim", "h", "c", "cmake", "txt", "md"]


# Dependencies

requires "nim >= 1.6.0"
requires "commandant >= 0.15.0"  # for piconim
requires "micros >= 0.1.8"  # for the after build hook
requires "futhark >= 0.9.2" # for bindings to lwip, cyw43_driver, btstack...

# Tests

task test, "Runs the test suite":
  exec "cmake -DPICO_SDK_FETCH_FROM_GIT=on -DPICO_BOARD=pico -S tests -B build/test_pico"
  exec "nimble c tests/test_pico"
  exec "cmake --build build/test_pico -- -j4"

  exec "cmake -DPICO_SDK_FETCH_FROM_GIT=on -DPICO_BOARD=pico_w -S tests -B build/test_pico_w"
  exec "nimble c tests/test_pico_w"
  exec "cmake --build build/test_pico_w -- -j4"

  when not defined(windows):
    rmDir "testproject_pico"
    rmDir "testproject_pico_w"
    exec "printf '\t\r\n\r\n\r\n\r\n\r\n' | piconim init testproject_pico && cd testproject_pico && nimble configure && nimble build"
    exec "printf '\t\r\n\r\n\r\n\r\n\r\n' | piconim init -b pico_w testproject_pico_w && cd testproject_pico_w && nimble configure && nimble build"


task examples, "Builds the examples":
  const examples = [
    "adc/hello_adc",
    "adc/onboard_temperature",
    "blink",
    "clocks/hello_48mhz",
    "clocks/hello_gpout",
    "clocks/hello_resus",
    "dma/hello_dma",
    "flash/hello_littlefs",
    "gpio/hello_7segment",
    "gpio/hello_gpio_irq",
    # "hello_pio/hello_pio",
    "hello_serial",
    "hello_stdio",
    "hello_timestart",
    "i2c/bus_scan",
    # "joystickdisplay",
    # "lightsensor",
    "multicore/hello_multicore",
    "pico_w/picow_blink",
    "pico_w/picow_ntp_client",
    "pico_w/picow_tls_client",
    "pico_w/picow_wifi_scan",
    "pwm/hello_pwm",
    "pwm/pwm_led_fade",
    "reset/hello_reset",
    "rtc/hello_rtc",
    "rtc/rtc_alarm",
    "system/unique_board_id",
    "timer/hello_timer",
    # "tinyusb/tinyusb",
    "uart/hello_uart",
    "watchdog/hello_watchdog",
    # "ws2812_pio/ws2812_pio",
  ]

  exec "cmake -DPICO_SDK_FETCH_FROM_GIT=on -DPICO_BOARD=pico -S examples -B build/examples"
  for ex in examples:
    exec "nim c examples/" & ex
  exec "cmake --build build/examples -- -j4"
  exec "cmake -DPICO_SDK_FETCH_FROM_GIT=on -DPICO_BOARD=pico_w -S examples -B build/examples"
  exec "cmake --build build/examples -- -j4"


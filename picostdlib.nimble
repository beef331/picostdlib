# Package

version       = "0.4.0"  # Don't forget to update version in piconim.nim (if needed)
author        = "The piconim contributors"
description   = "Nim bindings for the Raspberry Pi Pico SDK"
license       = "BSD-3-Clause"
srcDir        = "src"
backend       = "c"
namedBin["picostdlib/build_utils/piconim"] = "piconim"
installExt    = @["nim", "nims", "h", "c", "cmake", "txt", "md"]


# Dependencies

requires "nim >= 2.0.0"
requires "commandant >= 0.15.1"  # for piconim
requires "micros >= 0.1.16"  # for the after build hook
requires "futhark >= 0.13.7" # for bindings to lwip, cyw43_driver, btstack...

# Tests

task futharkgen, "Generate futhark cache":
  rmDir "src/picostdlib/futharkgen"
  exec "./piconim configure --project futharkgen --source src/picostdlib/build_utils/futharkgen --board pico_w"
  exec "./piconim build --project futharkgen src/picostdlib/build_utils/futharkgen/futharkgen --compileOnly"
  rmDir "build/futharkgen"

before install:
  exec "nimble build piconim"
  futharkgenTask()

task test, "Runs the test suite":
  selfExec "c -d:release -d:mock tests/test_mock"
  exec "nimble build"

  exec "./piconim configure --project tests_pico --source tests --board pico"
  exec "./piconim build --project tests_pico tests/test_pico"

  exec "./piconim configure --project tests_picow --source tests --board pico_w"
  exec "./piconim build --project tests_picow tests/test_pico_w"

  when not defined(windows):
    rmDir "testproject_pico"
    rmDir "testproject_pico_w"
    rmDir "testproject_piconim"
    exec "printf '\t\r\n\r\n\r\n\r\n\r\n' | ./piconim init testproject_pico && cd testproject_pico && nimble configure && nimble build"
    exec "printf '\t\r\n\r\n\r\n\r\n\r\n' | ./piconim init -b pico_w testproject_pico_w && cd testproject_pico_w && nimble configure && nimble build"
    exec "printf '\t\r\n\r\n\r\n\r\n\r\n' | ./piconim init testproject_piconim && cd testproject_piconim && ../piconim build src/testproject_piconim"


task examples, "Builds the examples":
  const examples = [
    "blink",
    "adc/hello_adc",
    "adc/read_vsys",
    "adc/onboard_temperature",
    "clocks/hello_48mhz",
    "clocks/hello_gpout",
    "clocks/hello_resus",
    "dma/hello_dma",
    "flash/hello_littlefs",
    "filesystem/hello_filesystem_flash",
    "filesystem/hello_filesystem_sd",
    "gpio/hello_7segment",
    "gpio/hello_gpio_irq",
    "hello_serial",
    "hello_timestart",
    "i2c/bus_scan",
    # "joystickdisplay",
    # "lightsensor",
    "multicore/hello_multicore",
    "pwm/hello_pwm",
    "reset/hello_reset",
    "rtc/hello_rtc",
    "rtc/rtc_alarm",
    "sleep/hello_sleep",
    "hello_stdio",
    "system/unique_board_id",
    "timer/hello_timer",
    # "tinyusb/tinyusb",
    "uart/hello_uart",
    "watchdog/hello_watchdog",
    # "ws2812_pio/ws2812_pio",
    # "freertos_blink",
  ]
  const examples_pico = [
    "pio/hello_pio",
    "pwm/pwm_led_fade",
  ]
  const examples_picow = [
    "pico_w/picow_blink",
    "pico_w/picow_http_client",
    "pico_w/picow_ntp_client",
    "pico_w/picow_tcp_client",
    "pico_w/picow_mqtt_client",
    "pico_w/picow_tls_client",
    "pico_w/picow_wifi_scan",
  ]

  exec "nimble build"

  exec "./piconim configure --project examples_pico --source examples --board pico"
  for ex in examples:
    let base = ex.split("/")[^1]
    exec "./piconim build --project examples_pico examples/" & ex & " --target " & base & " --compileOnly"
  for ex in examples_pico:
    let base = ex.split("/")[^1]
    exec "./piconim build --project examples_pico examples/" & ex & " --target " & base & " --compileOnly"
  exec "cmake --build build/examples_pico -- -j4"

  exec "./piconim configure --project examples_picow --source examples --board pico_w"
  for ex in examples:
    let base = ex.split("/")[^1]
    exec "./piconim build --project examples_picow examples/" & ex & " --target " & base & " --compileOnly"
  for ex in examples_picow:
    let base = ex.split("/")[^1]
    exec "./piconim build --project examples_picow examples/" & ex & " --target " & base & " --compileOnly"
  exec "cmake --build build/examples_picow -- -j4"

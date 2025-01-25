{.warning[UnusedImport]: off.}

# stdlib
import picostdlib

import picostdlib/hardware/regs/intctrl

import picostdlib/hardware/adc
import picostdlib/hardware/base
import picostdlib/hardware/claim
import picostdlib/hardware/clocks
block:
  discard ClockSys.getHz()
import picostdlib/hardware/divider as hardware_divider
import picostdlib/hardware/dma
import picostdlib/hardware/exception
block:
  SVCallException.restoreHandler(SVCallException.setExclusiveHandler(proc() {.cdecl.} = discard))
import picostdlib/hardware/flash
import picostdlib/hardware/gpio
import picostdlib/hardware/i2c
import picostdlib/hardware/interp
import picostdlib/hardware/irq
import picostdlib/hardware/pio
import picostdlib/hardware/pll
import picostdlib/hardware/powman
import picostdlib/hardware/pwm
import picostdlib/hardware/resets
import picostdlib/hardware/rosc
when picoIncludeRtcDatetime:
  import picostdlib/hardware/rtc
import picostdlib/hardware/spi
import picostdlib/hardware/sync as hardware_sync
import picostdlib/hardware/timer
import picostdlib/hardware/uart
import picostdlib/hardware/vreg
import picostdlib/hardware/watchdog
import picostdlib/hardware/xosc

import picostdlib/pico/util/datetime
import picostdlib/pico/util/pheap
import picostdlib/pico/util/queue

import picostdlib/pico/async_context
import picostdlib/pico/aon_timer
import picostdlib/pico/binary_info
block:
  bi_decl_include()
  bi_decl(bi_block_device(BINARY_INFO_MAKE_TAG('N', 'I'), "\"Nim\"", 0x1000, 1024, nil, {FlagRead, FlagWrite, FlagPtUnknown}))
import picostdlib/pico/bit_ops
import picostdlib/pico/bootrom
import picostdlib/pico/critical_section
import picostdlib/pico/divider
import picostdlib/pico/double
import picostdlib/pico/error
import picostdlib/pico/filesystem
import picostdlib/pico/flash
import picostdlib/pico/"float"
import picostdlib/pico/i2c_slave
import picostdlib/pico/lock_core
import picostdlib/pico/multicore
import picostdlib/pico/mutex
import picostdlib/pico/platform
import picostdlib/pico/rand
import picostdlib/pico/runtime_init
import picostdlib/pico/sem
import picostdlib/pico/sleep
import picostdlib/pico/stdio
import picostdlib/pico/sync
import picostdlib/pico/time
import picostdlib/pico/types
import picostdlib/pico/unique_id
import picostdlib/pico/version

# misc
import picostdlib/asyncdispatch
import picostdlib/memoryinfo
import picostdlib/power
import picostdlib/promise
import picostdlib/sevensegdisplay

# futhark stuff
import picostdlib/lib/littlefs
# import picostdlib/lib/freertos

# examples
import "../examples/blink"
import "../examples/hello_async"
import "../examples/adc/hello_adc"
import "../examples/adc/onboard_temperature"
import "../examples/adc/read_vsys"
import "../examples/clocks/hello_48mhz"
import "../examples/clocks/hello_gpout"
import "../examples/clocks/hello_resus"
import "../examples/dma/hello_dma"
import "../examples/filesystem/hello_filesystem_flash"
import "../examples/filesystem/hello_filesystem_sd"
import "../examples/flash/hello_littlefs"
import "../examples/gpio/hello_gpio_irq"
import "../examples/i2c/bus_scan"
import "../examples/multicore/hello_multicore"
when not defined(picoCyw43Supported):
  import "../examples/pio/hello_pio"
  import "../examples/pwm/pwm_led_fade"
import "../examples/pwm/hello_pwm"
import "../examples/reset/hello_reset"
when picoIncludeRtcDatetime:
  import "../examples/rtc/hello_rtc"
  import "../examples/rtc/rtc_alarm"
import "../examples/system/unique_board_id"
import "../examples/timer/hello_timer"
import "../examples/uart/hello_uart"
import "../examples/watchdog/hello_watchdog"
import "../examples/hello_serial"
import "../examples/sleep/hello_sleep"
import "../examples/hello_stdio"
import "../examples/hello_timestart"
# import "../examples/freertos_blink"

# import and include blink from template
import "../template/src/blink"
include "../template/src/blink"

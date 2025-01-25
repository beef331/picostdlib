import ./picostdlib/[
  pico,
  pico/stdio,
  pico/time,
  hardware/gpio,
  hardware/uart,
  pico/binary_info,
  pico/platform,
  pico/util/datetime, pico/util/queue, pico/util/pheap,
  pico/error
]
export
  pico,
  stdio,
  time,
  gpio,
  uart,
  binary_info,
  platform,
  datetime, queue, pheap,
  error

{.push header: "pico/stdlib.h".}

proc setupDefaultUart*() {.importc: "setup_default_uart".}
  ## Set up the default UART and assign it to the default GPIOs
  ##
  ## By default this will use UART 0, with TX to pin GPIO 0,
  ## RX to pin GPIO 1, and the baudrate to 115200
  ##
  ## Calling this method also initializes stdin/stdout over UART if the
  ## @ref pico_stdio_uart library is linked.
  ##
  ## Defaults can be changed using configuration defines,
  ##  PICO_DEFAULT_UART_INSTANCE,
  ##  PICO_DEFAULT_UART_BAUD_RATE
  ##  PICO_DEFAULT_UART_TX_PIN
  ##  PICO_DEFAULT_UART_RX_PIN

proc setSysClock48mhz*() {.importc: "set_sys_clock_48mhz".}
  ## Initialise the system clock to 48MHz
  ##
  ## Set the system clock to 48MHz, and set the peripheral clock to match.

proc setSysClockPll*(vcoFreq: uint32; postDiv1, postDiv2: cuint) {.importc: "set_sys_clock_pll".}
  ## Initialise the system clock
  ##
  ## \param vco_freq The voltage controller oscillator frequency to be used by the SYS PLL
  ## \param post_div1 The first post divider for the SYS PLL
  ## \param post_div2 The second post divider for the SYS PLL.
  ##
  ## See the PLL documentation in the datasheet for details of driving the PLLs.

proc checkSysClockKhz*(freqKhz: uint32; vcoFreqOut, postDiv1Out, postDiv2Out: ptr cuint): bool {.importc: "check_sys_clock_khz".}
  ## Check if a given system clock frequency is valid/attainable
  ##
  ## \param freq_khz Requested frequency
  ## \param vco_freq_out On success, the voltage controlled oscillator frequency to be used by the SYS PLL
  ## \param post_div1_out On success, The first post divider for the SYS PLL
  ## \param post_div2_out On success, The second post divider for the SYS PLL.
  ## @return true if the frequency is possible and the output parameters have been written.

proc setSysClockKhz*(freqKhz: uint32; required: bool): bool {.importc: "set_sys_clock_khz".}
  ## Attempt to set a system clock frequency in khz
  ##
  ## Note that not all clock frequencies are possible; it is preferred that you
  ## use src/rp2_common/hardware_clocks/scripts/vcocalc.py to calculate the parameters
  ## for use with set_sys_clock_pll
  ##
  ## \param freq_khz Requested frequency
  ## \param required if true then this function will assert if the frequency is not attainable.
  ## \return true if the clock was configured

{.pop.}

import ./base, ./gpio, ../pico/runtime_init
export base, gpio, clocksInit

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_clocks/include".}

when picoRp2040:
  type
    ClocksFc0Src* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_FC0_SRC
      ## Clock sent to frequency counter, set to 0 when not required.
      ## Writing to this register initiates the frequency count
      Null
      PllSysClksrcPrimary
      PllUsbClksrcPrimary
      RoscClksrc
      RoscClksrcPh
      XoscClksrc
      ClksrcGpin0
      ClksrcGpin1
      ClkRef
      ClkSys
      ClkPeri
      ClkUsb
      ClkAdc
      ClkRtc

    ClocksClkGpoutCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_CLK_GPOUT0_CTRL_AUXSRC
      ## Selects the auxiliary clock source, will glitch when switching
      ClksrcPllSys
      ClksrcGpin0
      ClksrcGpin1
      ClksrcPllUsb
      RoscClksrc
      XoscClksrc
      ClkSys
      ClkUsb
      ClkAdc
      ClkRtc
      ClkRef

    ClocksClkRefCtrlSrc* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_CLK_REF_CTRL_SRC
      ## Selects the clock source glitchlessly, can be changed on-the-fly
      RoscClksrcPh
      ClksrcClkRefAux
      XoscClksrc

    ClocksClkRtcCtrlAuxsrc* {.pure, size: sizeof(uint32).} = enum
      ## Selects the auxiliary clock source, will glitch when switching
      ClksrcPllUsb
      ClksrcPllSys
      RoscClksrcPh
      XoscClksrc
      ClksrcGpin0
      ClksrcGpin1

else: # rp2350
  type
    ClocksFc0Src* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_FC0_SRC
      ## Clock sent to frequency counter, set to 0 when not required.
      ## Writing to this register initiates the frequency count
      Null
      PllSysClksrcPrimary
      PllUsbClksrcPrimary
      RoscClksrc
      RoscClksrcPh
      XoscClksrc
      ClksrcGpin0
      ClksrcGpin1
      ClkRef
      ClkSys
      ClkPeri
      ClkUsb
      ClkAdc
      ClkHstx
      LposcClksrc
      OtpClk2fc
      PllUsbClksrcPrimaryDft

    ClocksClkGpoutCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_CLK_GPOUT0_CTRL_AUXSRC
      ## Selects the auxiliary clock source, will glitch when switching
      ClksrcPllSys
      ClksrcGpin0
      ClksrcGpin1
      ClksrcPllUsb
      ClksrcPllUsbPrimaryRefOpcg
      RoscClksrc
      XoscClksrc
      LposcClksrc
      ClkSys
      ClkUsb
      ClkAdc
      ClkRef
      ClkPeri
      ClkHstx
      OtpClk2fc

    ClocksClkRefCtrlSrc* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_CLK_REF_CTRL_SRC
      ## Selects the clock source glitchlessly, can be changed on-the-fly
      RoscClksrcPh
      ClksrcClkRefAux
      XoscClksrc
      LposcClksrc

    ClocksClkHstxCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
      ## CLOCKS_CLK_HSTX_CTRL_AUXSRC
      ## Selects the auxiliary clock source, will glitch when switching
      ClkSys
      ClksrcPllSys
      ClksrcPllUsb
      ClksrcGpin0
      ClksrcGpin1

    # CLOCKS_DFTCLK_XOSC_CTRL_SRC
    # CLOCKS_DFTCLK_ROSC_CTRL_SRC
    # CLOCKS_DFTCLK_LPOSC_CTRL_SRC

type
  ClocksClkSysCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
    ## CLOCKS_CLK_SYS_CTRL_AUXSRC
    ## Selects the auxiliary clock source, will glitch when switching
    ClksrcPllSys
    ClksrcPllUsb
    RoscClksrc
    XoscClksrc
    ClksrcGpin0
    ClksrcGpin1

  ClocksClkSysCtrlSrc* {.pure, size: sizeof(uint32).} = enum
    ## CLOCKS_CLK_SYS_CTRL_SRC
    ## Selects the clock source glitchlessly, can be changed on-the-fly
    ClkRef
    ClksrcClkSysAux

  ClocksClkPeriCtrlAuxsrc* {.pure, size: sizeof(uint32).} = enum
    ## CLOCKS_CLK_PERI_CTRL_AUXSRC
    ## Selects the auxiliary clock source, will glitch when switching
    ClkSys
    ClksrcPllSys
    ClksrcPllUsb
    RoscClksrcPh
    XoscClksrc
    ClksrcGpin0
    ClksrcGpin1

  ClocksClkUsbCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
    ## CLOCKS_CLK_USB_CTRL_AUXSRC
    ## Selects the auxiliary clock source, will glitch when switching
    ClksrcPllUsb
    ClksrcPllSys
    RoscClksrcPh
    XoscClksrc
    ClksrcGpin0
    ClksrcGpin1

  ClocksClkAdcCtrlAuxSrc* {.pure, size: sizeof(uint32).} = enum
    ## CLOCKS_CLK_ADC_CTRL_AUXSRC
    ## Selects the auxiliary clock source, will glitch when switching
    ClksrcPllUsb
    ClksrcPllSys
    RoscClksrcPh
    XoscClksrc
    ClksrcGpin0
    ClksrcGpin1


{.push header: "hardware/clocks.h".}

const
  CtrlAuxsrcValueClksrcPllSys* = 0'u32
  CtrlSrcValueClksrcClkSysAux* = 1'u32

let
  ## Todo: add more constants
  ClocksSleepEn0ClkRtcRtcBits* {.importc: "CLOCKS_SLEEP_EN0_CLK_RTC_RTC_BITS".}: uint32
  ClocksSleepEn1ClkUsbUsbctrlBits* {.importc: "CLOCKS_SLEEP_EN1_CLK_USB_USBCTRL_BITS".}: uint32
  ClocksSleepEn1ClkSysTimerBits* {.importc: "CLOCKS_SLEEP_EN1_CLK_SYS_TIMER_BITS".}: uint32
  CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX* {.importc: "CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX".}: uint32
  CLOCKS_CLK_SYS_CTRL_AUXSRC_VALUE_CLKSRC_PLL_SYS* {.importc: "CLOCKS_CLK_SYS_CTRL_AUXSRC_VALUE_CLKSRC_PLL_SYS".}: uint32
  ClocksSleepEn0ClkSysPllUsbBits* {.importc: "CLOCKS_SLEEP_EN0_CLK_SYS_PLL_USB_BITS".}: uint32
  ClocksSleepEn1ClkSysUsbctrlBits* {.importc: "CLOCKS_SLEEP_EN1_CLK_SYS_USBCTRL_BITS".}: uint32

  # rp2350
  ClocksSleepEn0ClkRefPowmanBits* {.importc: "CLOCKS_SLEEP_EN0_CLK_REF_POWMAN_BITS".}: uint32
  CLOCKS_SLEEP_EN1_CLK_REF_TICKS_BITS* {.importc: "CLOCKS_SLEEP_EN1_CLK_REF_TICKS_BITS".}: uint32
  CLOCKS_SLEEP_EN1_CLK_SYS_TIMER0_BITS* {.importc: "CLOCKS_SLEEP_EN1_CLK_SYS_TIMER0_BITS".}: uint32


when picoRp2040:
  type
    ClockIndex* {.pure, importc: "clock_handle_t".} = enum
      ## Enumeration identifying a hardware clock on rp2040
      ClockGpOut0 ## GPIO Muxing 0
      ClockGpOut1 ## GPIO Muxing 1
      ClockGpOut2 ## GPIO Muxing 2
      ClockGpOut3 ## GPIO Muxing 3
      ClockRef    ## Watchdog and timers reference clock
      ClockSys    ## Processors, bus fabric, memory, memory mapped registers
      ClockPeri   ## Peripheral clock for UART and SPI
      ClockUsb    ## USB clock
      ClockAdc    ## ADC clock
      ClockRtc    ## Real Time Clock
      ClockCount

else:
  type
    ClockIndex* {.pure, importc: "clock_handle_t".} = enum
      ## Enumeration identifying a hardware clock on rp2350
      ClockGpOut0 ## GPIO Muxing 0
      ClockGpOut1 ## GPIO Muxing 1
      ClockGpOut2 ## GPIO Muxing 2
      ClockGpOut3 ## GPIO Muxing 3
      ClockRef    ## Watchdog and timers reference clock
      ClockSys    ## Processors, bus fabric, memory, memory mapped registers
      ClockPeri   ## Peripheral clock for UART and SPI
      ClockHstx   ## HSTX clock
      ClockUsb    ## USB clock
      ClockAdc    ## ADC clock
      ClockCount

type
  ClocksHw* {.importc: "clocks_hw_t".} = object
    sleep_en0*: IoRw32
    sleep_en1*: IoRw32

  ResusCallback* {.importc: "resus_callback_t".} = proc () {.cdecl.}

let clocksHw* {.importc: "clocks_hw".}: ptr ClocksHw

const
  KHz* = 1_000
  MHz* = 1_000_000

proc configure*(clkInd: ClockIndex; src, auxSrc, srcFreq, freq: uint32): bool {.importc: "clock_configure".}
  ## Configure the specified clock.
  ##
  ## See the tables in the description for details on the possible values for clock sources.
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **clkInd**     The clock to configure
  ## **src**        The main clock source, can be 0.
  ## **auxSrc**     The auxiliary clock source, which depends on which clock is being set. Can be 0
  ## **srcFreq**    Frequency of the input clock source
  ## **freq**       Requested frequency
  ## =============  ======

proc stop*(clkInd: ClockIndex) {.importc: "clock_stop".}
  ## Stop the specified clock
  ##
  ## **Parameters:**
  ##
  ## ===========  ======
  ## **clkInd**    The clock to stop
  ## ===========  ======

proc getHz*(clkInd: ClockIndex): uint32 {.importc: "clock_get_hz".}
  ## Get the current frequency of the specified clock
  ##
  ## **Parameters:**
  ##
  ## ===========  ======
  ## **clkInd**    Clock
  ## ===========  ======
  ##
  ## **Returns:** Clock frequency in Hz

proc frequencyCountKHz*(src: ClocksFc0Src): uint32 {.importc: "frequency_count_khz".}
  ## Measure a clocks frequency using the Frequency counter.
  ##
  ## Uses the inbuilt frequency counter to measure the specified clocks frequency.
  ## Currently, this function is accurate to +-1KHz. See the datasheet for more details.

proc setReportedHz*(clkInd: ClockIndex; hz: cuint) {.importc: "clock_set_reported_hz".}
  ## Set the "current frequency" of the clock as reported by clock_get_hz without actually changing the clock
  ##
  ## **Parameters:**
  ##
  ## ===========  ======
  ## **clkInd**    Clock
  ## **hz**        frequency in hz to set the new reporting value of the clock
  ## ===========  ======

proc clocksEnableResus*(resusCallback: ResusCallback) {.importc: "clocks_enable_resus".}
  ## Enable the resus function. Restarts clk_sys if it is accidentally stopped.
  ##
  ## The resuscitate function will restart the system clock if it falls below a certain speed (or stops). This
  ## could happen if the clock source the system clock is running from stops. For example if a PLL is stopped.
  ##
  ## **Parameters:**
  ##
  ## ==================  ======
  ## **resusCallback**    a function pointer provided by the user to call if a resus event happens.
  ## ==================  ======

proc initClockIntFrac*(gpio: Gpio; src: ClocksClkGpoutCtrlAuxSrc; divInt: uint32; divFrac: uint8) {.importc: "clock_gpio_init_int_frac".}
  ## Output an optionally divided clock to the specified gpio pin.
  ##
  ## \param gpio The GPIO pin to output the clock to. Valid GPIOs are: 21, 23, 24, 25. These GPIOs are connected to the GPOUT0-3 clock generators.
  ## \param src  The source clock. See the register field CLOCKS_CLK_GPOUT0_CTRL_AUXSRC for a full list. The list is the same for each GPOUT clock generator.
  ## \param div_int  The integer part of the value to divide the source clock by. This is useful to not overwhelm the GPIO pin with a fast clock. this is in range of 1..2^24-1.
  ## \param div_frac The fractional part of the value to divide the source clock by. This is in range of 0..255 (/256).

proc initClock*(gpio: Gpio; src: ClocksClkGpoutCtrlAuxSrc; `div`: cfloat) {.importc: "clock_gpio_init".}
  ## Output an optionally divided clock to the specified gpio pin.
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **gpio**    The GPIO pin to output the clock to. Valid GPIOs are: 21, 23, 24, 25. These GPIOs are connected to the GPOUT0-3 clock generators.
  ## **src**     The source clock. See the register field CLOCKS_CLK_GPOUT0_CTRL_AUXSRC for a full list. The list is the same for each GPOUT clock generator.
  ## **div**     The amount to divide the source clock by. This is useful to not overwhelm the GPIO pin with a fast clock.
  ## =========  ======

proc configureGpin*(clkInd: ClockIndex; gpio: Gpio; srcFreq, freq: uint32): bool {.importc: "clock_configure_gpin".}
  ## Configure a clock to come from a gpio input
  ##
  ## **Parameters:**
  ##
  ## ============  ======
  ## **clkInd**     The clock to configure
  ## **gpio**       The GPIO pin to run the clock from. Valid GPIOs are: 20 and 22.
  ## **srcFreq**    Frequency of the input clock source
  ## **freq**       Requested frequency
  ## ============  ======

{.pop.}

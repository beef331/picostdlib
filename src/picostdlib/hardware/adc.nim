import ./base
import ./gpio

export base, gpio

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_adc/include".}

type AdcInput* {.pure, size: sizeof(byte).} = enum
  ## ADC input. 0...3 are GPIOs 26...29 respectively. Input 4 is the onboard temperature sensor.
  Adc26 = 0, Adc27 = 1, Adc28 = 2, Adc29 = 3, AdcTemp = 4

const ThreePointThreeConv* = 3.3f / (1 shl 12)
  ## Useful for reading inputs from a 3.3v source

{.push header: "hardware/adc.h".}

let
  ADC_CS_EN_BITS* {.importc: "ADC_CS_EN_BITS".}: uint

type
  AdcHw* {.importc: "adc_hw_t".} = object
    cs*: IoRw32
    result*: IoRo32
    fcs*: IoRw32
    fifo*: IoRo32
    `div`*: IoRw32
    intr*: IoRo32
    inte*: IoRw32
    intf*: IoRw32
    ints*: IoRo32

let
  adcHw* {.importc: "adc_hw".}: ptr AdcHw

proc adcInit*() {.importc: "adc_init".}
  ## Initialise the ADC HW

proc initAdc*(gpio: range[Gpio(26) .. Gpio(29)]) {.importc: "adc_gpio_init".}
  ## Initialise the gpio for use as an ADC pin
  ##
  ## Prepare a GPIO for use with ADC, by disabling all digital functions.
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **gpio**    The GPIO number to use. Allowable GPIO numbers are 26 to 29 inclusive.
  ## =========  ======

proc selectInput*(input: AdcInput) {.importc: "adc_select_input".}
  ## ADC input select
  ##
  ## Select an ADC input. 0...3 are GPIOs 26...29 respectively.
  ## Input 4 is the onboard temperature sensor.
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **input**   Input to select.
  ## =========  ======

proc adcGetSelectedInput*(): AdcInput {.importc: "adc_get_selected_input".}
  ## Get the currently selected ADC input channel
  ##
  ## **Returns:** The currently selected input channel. 0...3 are GPIOs 26...29 respectively. Input 4 is the onboard temperature sensor.

proc setRoundRobin*(inputMask: set[AdcInput]) {.importc: "adc_set_round_robin".}
  ## Round Robin sampling selector
  ##
  ## This function sets which inputs are to be run through in round robin mode.
  ## Value between 0 and 0x1f (bit 0 to bit 4 for GPIO 26 to 29 and temperature sensor input respectively)
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **inputMask**   A bit pattern indicating which of the 5 inputs are to be sampled. Write a value of 0 to disable round robin sampling.
  ## =============  ======

proc adcSetTempSensorEnabled*(enable: bool) {.importc: "adc_set_temp_sensor_enabled".}
  ## Enable the onboard temperature sensor
  ##
  ## **Parameters:**
  ##
  ## ===========  ======
  ## **enable**    Set true to power on the onboard temperature sensor, false to power off.
  ## ===========  ======

proc adcRead*(): uint16 {.importc: "adc_read".}
  ## Perform a single conversion
  ##
  ## Performs an ADC conversion, waits for the result, and then returns it.
  ##
  ## **Returns:** Result of the conversion.

proc adcRun*(run: bool) {.importc: "adc_run".}
  ## Enable or disable free-running sampling mode
  ##
  ## **Parameters:**
  ##
  ## ========  ======
  ## **run**    false to disable, true to enable free running conversion mode.
  ## ========  ======

proc adcSetClkdiv*(clkdiv: cfloat) {.importc: "adc_set_clkdiv".}
  ## Set the ADC Clock divisor
  ##
  ## Period of samples will be (1 + div) cycles on average. Note it takes 96 cycles to perform a conversion,
  ## so any period less than that will be clamped to 96.
  ##
  ## **Parameters:**
  ##
  ## ===========  ======
  ## **clkdiv**    If non-zero, conversion will be started at intervals rather than back to back.
  ## ===========  ======

proc adcFifoSetup*(en: bool, dreqEn: bool, dreqThresh: uint16, errInFifo: bool, byteShift: bool) {.importc: "adc_fifo_setup".}
  ## Setup the ADC FIFO
  ##
  ## FIFO is 4 samples long, if a conversion is completed and the FIFO is full, the result is dropped.
  ##
  ## **Parameters:**
  ##
  ## ===============  ======
  ## **en**            Enables write each conversion result to the FIFO
  ## **dreqEn**        Enable DMA requests when FIFO contains data
  ## **dreqThresh**    Threshold for DMA requests/FIFO IRQ if enabled.
  ## **errInFifo**     If enabled, bit 15 of the FIFO contains error flag for each sample
  ## **byteShift**     Shift FIFO contents to be one byte in size (for byte DMA) - enables DMA to byte buffers.
  ## ===============  ======

proc adcFifoIsEmpty*(): bool {.importc: "adc_fifo_is_empty".}
  ## Check FIFO empty state
  ##
  ## **returns** Returns true if the FIFO is empty

proc adcFifoGetLevel*(): uint8 {.importc: "adc_fifo_get_level".}
  ## Get number of entries in the ADC FIFO
  ##
  ## The ADC FIFO is 4 entries long. This function will return how many samples are currently present.

proc adcFifoGet*(): uint16 {.importc: "adc_fifo_get".}
  ## Get ADC result from FIFO
  ##
  ## Pops the latest result from the ADC FIFO.

proc adcFifoGetBlocking*(): uint16 {.importc: "adc_fifo_get_blocking".}
  ## Wait for the ADC FIFO to have data.
  ##
  ## Blocks until data is present in the FIFO

proc adcFifoDrain*() {.importc: "adc_fifo_drain".}
  ## Drain the ADC FIFO
  ##
  ## Will wait for any conversion to complete then drain the FIFO, discarding any results.

proc adcIrqSetEnabled*(enabled: bool) {.importc: "adc_irq_set_enabled".}
  ## Enable/Disable ADC interrupts.
  ##
  ## **Parameters:**
  ##
  ## ============  ======
  ## **enabled**    Set to true to enable the ADC interrupts, false to disable
  ## ============  ======

{.pop.}

# Nim helpers

func toAdcInput*(gpio: range[26.Gpio .. 29.Gpio]): AdcInput =
  AdcInput(gpio.ord - 26)

proc adcInitialized*(): bool =
  return (adcHw.cs and ADC_CS_EN_BITS) != 0

func read*(adc: AdcInput): uint16 =
  adc.selectInput()
  adcRead()

func read*(gpio: Gpio): uint16 =
  gpio.toAdcInput().read()

var adcRunLock {.compileTime.}: int
template withAdcRunLock*(body: untyped) =
  adcRun(true)
  {.locks: [adcRunLock].}:
    try:
      body
    finally:
      adcRun(false)

proc adcReadTemp*(): float32 =
  if not adcInitialized(): return 0.0
  adcSetTempSensorEnabled(true)
  return 27.0f - (AdcTemp.read().float32 * ThreePointThreeConv - 0.706f) / 0.001721f

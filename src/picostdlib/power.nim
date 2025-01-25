import ./hardware/adc
import ./pico

when defined(picoCyw43Supported):
  import picostdlib/pico/cyw43_arch
  export cyw43_arch

let VsysAdcInput = VsysPin.toAdcInput()

proc powerSourceBattery*(): bool =
  when defined(picoCyw43Supported):
    return Cyw43WlGpioVbusPin.get() == Low
  else:
    VbusPin.setFunction(Sio)
    return VbusPin.get() == Low

proc powerSourceVoltage*(sampleCount: int = 10): float32 =
  if not adcInitialized():
    return 0.0

  when defined(picoCyw43Supported):
    # Make sure cyw43 is awake
    withLwipLock:
      discard Cyw43WlGpioVbusPin.get()

  VsysPin.initAdc()
  VsysAdcInput.selectInput()
  adcFifoSetup(en = true, dreqEn = false, dreqThresh = 0, errInFifo = false, byteShift = false)

  var vsys = 0
  withAdcRunLock:
    var ignoreCount = sampleCount
    while not adcFifoIsEmpty() or (dec(ignoreCount); ignoreCount) > 0:
      discard adcFifoGetBlocking()

    for i in 0 ..< sampleCount:
      vsys += adcFifoGetBlocking().int

  adcFifoDrain()

  vsys = vsys * 3 div sampleCount

  # calculate voltage
  return float32(vsys) * ThreePointThreeConv

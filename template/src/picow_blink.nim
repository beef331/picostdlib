import picostdlib, picostdlib/pico/cyw43_arch

if cyw43ArchInit() == PicoErrorNone:
  while true:
    Cyw43WlGpioLedPin.put(High)
    sleepMs(250)
    Cyw43WlGpioLedPin.put(Low)
    sleepMs(250)

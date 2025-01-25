import std/strformat

import picostdlib
import picostdlib/hardware/adc
import picostdlib/power

when defined(picoCyw43Supported):
  import picostdlib/pico/cyw43_arch

type
  PowerSource = enum
    BusPowered = "Bus"
    BatteryPowered = "Battery"

proc main() =
  stdioInitAll()

  adcInit()

  when defined(picoCyw43Supported):
    if cyw43ArchInit() != PicoOk:
      echo "failed to initialize cyw43"
      return
  else:
    DefaultLedPin.init()
    DefaultLedPin.setDir(Out)

  while true:
    DefaultLedPin.put(High)

    let batteryStatus = powerSourceBattery()
    var voltage = powerSourceVoltage()

    var percentStr = ""
    if batteryStatus:
      const minBatteryVolts = 3.0f
      const maxBatteryVolts = 4.2f
      let percentVal = int ((voltage - minBatteryVolts) / (maxBatteryVolts - minBatteryVolts)) * 100
      percentStr = &", {percentVal} %"

    let tempC = adcReadTemp()

    DefaultLedPin.put(Low)

    echo &"Power source: {batteryStatus.PowerSource}, {voltage:.3f} V{percentStr}, temp {tempC:.2f} °C"

    sleepMs(1000)

  when defined(picoCyw43Supported):
    cyw43ArchDeinit()

main()

import std/strformat
import picostdlib
import picostdlib/hardware/adc

type
  TempUnit = enum
    TempUnitC, TempUnitF

proc unitStr(unit: TempUnit): string =
  if unit == TempUnitC:
    "°C"
  else:
    "°F"

const tempUnit = TempUnitC

proc readOnboardTemperature(unit: TempUnit): float32 =
  let adc = adcRead().float32 * ThreePointThreeConv
  let tempC = 27.0f - (adc - 0.706f) / 0.001721f
  case unit:
  of TempUnitC:
    return tempC
  of TempUnitF:
    return tempC * 9 / 5 + 32

stdioInitAll()

DefaultLedPin.init()
DefaultLedPin.setDir(Out)

adcInit()
adcSetTempSensorEnabled(true)
AdcTemp.selectInput()

while true:
  let temperature = readOnboardTemperature(tempUnit)
  echo &"Onboard temperature = {temperature:.2f} {unitStr(tempUnit)}"
  DefaultLedPin.put(High)
  sleepMs(10)
  DefaultLedPin.put(Low)
  sleepMs(990)

import picostdlib
import picostdlib/hardware/adc

stdioInitAll()

echo "ADC Example, measuring GPIO26"

const adcPin = Gpio(26)

adcInit()
adcPin.initAdc()
adcPin.toAdcInput().selectInput()

while true:
  let res = adcRead()
  echo "Raw value: " & $res & " voltage: " & $(res.float * ThreePointThreeConv)
  sleepMs(500)

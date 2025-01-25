import picostdlib
import picostdlib/hardware/adc

stdioInitAll()
adcInit()
Gpio(26).init()
Gpio(27).init()

while true:
  Adc26.selectInput()
  let xRaw = adcRead()
  Adc27.selectInput()
  let yRaw = adcRead()
  const
    width = 40u16
    max = (1 shl 12) - 1

  let
    xPos = ((xRaw * width) div max * 7).clamp(0, max -
        1) # I'm using potentiometers that return something like 3400 - 4095
    yPos = ((yRaw * width) div max * 7).clamp(0, max -
        1) # I'm using potentiometers that return something like 3400 - 4095

  print("X: [")
  for x in 0u16..<width:
    if x == xPos:
      print("o")
    else:
      print(" ")
  print("] Y: [")
  for y in 0u16..<width:
    if y == yPos:
      print("o")
    else:
      print(" ")
  print "] \n"

  sleepMs(50)

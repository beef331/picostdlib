import picostdlib
import picostdlib/sevensegdisplay

#This module counts seconds displaying the current on a seven segment display

proc setupPins =
  # My pins are gp 0 to 8 for panel
  var i = 0
  for x in SevenSeg:
    SevenSegPins[x] = i.Gpio
    inc i
  let
    gPin = SevenSegPins[f]
  SevenSegPins[f] = SevenSegPins[g]
  SevenSegPins[g] = gPin

stdioInitAll()

setupPins()
initPins()

while true:
  for toDraw in CharacterName:
    toDraw.draw()
    sleepMs(1000)

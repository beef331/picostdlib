import picostdlib

DefaultLedPin.init()
DefaultLedPin.setDir(Out)

while true:
  DefaultLedPin.put(High)
  sleepMs(250)
  DefaultLedPin.put(Low)
  sleepMs(250)

import picostdlib

proc callback(pin: Gpio, eventMask: uint32) {.cdecl.} =
  let events = cast[set[GpioIrqLevel]](eventMask)
  echo $pin & ": " & $events

stdioInitAll()

echo "Hello GPIO IRQ"

Gpio(2).setIrqEnabledWithCallback({EdgeRise, EdgeFall}, true, callback)

while true: tightLoopContents()

import picostdlib

stdioInitAll()

let led = DefaultLedPin
led.init()
led.setDir(Out)
sleepMs(600)

while true:
  let res = getcharTimeoutUs(300)
  if res < 0:
    echo "Stdio error: ", $res.PicoErrorCode
    sleepMs(1000)
  else:
    let charX = res.char

    if charX != '\255':
      echo "Char put -> " & charX
      if charX == '1': # turn on led if recive 1 (char)
        led.put(High)
      elif charX == '0': # turn off led if recive 0 (char)
        led.put(Low)
      else: # blink a led in other case!
        for _ in 0..3:
          led.put(High)
          sleepMs(300)
          led.put(Low)
          sleepMs(100)

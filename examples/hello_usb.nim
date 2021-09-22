import picostdlib/[gpio]
import picostdlib

stdioInitAll() #is necessary for initializzate usb

#const led1 = 25.Gpio; led1.init(); led1.setDir(Out) #enable a led on board try (old statment)
setupGpio(led1, 25.Gpio, Out) #new "sugar" style statement
var charX: char #create a char variable (getCharwithTimeOut return a char!!)
sleep(600)

while true:
  charX = getCharWithTimeOut(300)
  if charX  != '\255':
    print("Char put -> " & charX & '\n')
    if charX == '1': #turn on led if recive 1 (char)
      led1.put(High)
    elif charX == '0': #turn off led if recive 0 (char)
      led1.put(Low)
    else: #blink a led in other case!
      for _ in 0..3:
        led1.put(High)
        sleep(300)
        led1.put(Low)
        sleep(100)

#use line termination for this example = none!!

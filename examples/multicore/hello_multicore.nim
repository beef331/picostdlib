import picostdlib
import picostdlib/pico/multicore

stdioInitAll()

proc coreOneActv() {.cdecl.} = #this function works on core1 (you must use pragma {.cdecl.})
  var value: uint32 = multicoreFifoPopBlocking() #read the value in FIFO(core0-->core1) and save in "value".
  print("Core1 Active" & '\n')
  for addx in 1..10:
    value.inc() #core1 increase "value".
    print("@On Core 1 --> " & $value & '\n')
    sleepMs(600)
  multicoreFifoPushBlocking(value) # push the value of "value" on the FIFO (core1-->core0).
  while true: tightLoopContents()

var counter: uint32 = 0 #counting variable.
var step: uint32 = 0 #step variable.

while true:
  if counter == 10 + step:
    multicoreResetCore1() #reset core1 (whitout this the core1 does not start again).
    multicoreLaunchCore1(coreOneActv) #launch the function "coreOneActv()" on the core1 (core0-->core1).
    multicoreFifoPushBlocking(counter) #write on the FIFO the value in "counter".
    counter.inc() #core0 increase "counter".
  else:
    print("@On Core 0 --> " & $counter & '\n') #print  the variable "counter" increased by core0.
    counter.inc() #core0 increase "counter".
    sleepMs(1200)

  if multicoreFifoRvalid() == true: #check the FIFO (core1-->core0) if it has valid values (uint32).
    step = multicoreFifoPopBlocking()
    print("Next Activation Core 1: " & $(step + 10) & '\n')

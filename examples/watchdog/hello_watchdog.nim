import picostdlib
import picostdlib/hardware/watchdog

stdioInitAll()

if watchdogCausedReboot():
  echo "Reboot by WatchDog!"
else:
  echo "Clean Boot"

  # Enable the watchdog, requiring the watchdog to be updated every 100ms or the chip will reboot
  # second arg is pause on debug which means the watchdog will pause when stepping through code
  watchdogEnable(100, true)

  for i in countup(0, 5):
    echo "Updating Watchdog" & $i
    watchdogUpdate()

  echo "Waiting to be Rebooted by Watchdog"

  # Wait in an infinite loop and don't update the watchdog so it reboots us
  while true:
    tightLoopContents()

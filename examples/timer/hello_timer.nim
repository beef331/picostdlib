import std/volatile
import picostdlib
import picostdlib/hardware/timer

var timerFired = false

proc alarmCallback(id: AlarmId; userData: pointer): int64 {.cdecl.} =
  echo "Timer " & $id & " fired!"
  volatileStore(timerFired.addr, true)
  # Can return a value here in us to fire in the future
  return 0

proc repeatingTimerCallback(t: ptr RepeatingTimer): bool {.cdecl.} =
  echo "Repeat at " & $timeUs64()
  return true

# need to be inside proc to use volatile
# https://github.com/nim-lang/Nim/issues/14623
proc main() =
  stdioInitAll()
  echo "Hello Timer!"

  # Call alarm_callback in 2 seconds
  discard addAlarmInMs(2000, alarmCallback, nil, false)

  # Wait for alarm callback to set timer_fired
  while not volatileLoad(timerFired.addr):
    tightLoopContents()

  # Create a repeating timer that calls repeating_timer_callback.
  # If the delay is > 0 then this is the delay between the previous callback ending and the next starting.
  # If the delay is negative (see below) then the next call to the callback will be exactly 500ms after the
  # start of the call to the last callback

  var timer: RepeatingTimer
  discard addRepeatingTimerMs(500, repeatingTimerCallback, nil, timer.addr)
  sleepMs(3000)
  var cancelled = addr(timer).cancel()
  echo "cancelled... " & $cancelled
  sleepMs(2000)

  # Negative delay so means we will call repeating_timer_callback, and call it again
  # 500ms later regardless of how long the callback took to execute
  discard addRepeatingTimerMs(-500, repeatingTimerCallback, nil, timer.addr)
  sleepMs(3000)
  cancelled = addr(timer).cancel()
  echo "cancelled... " & $cancelled
  sleepMs(2000)

  echo "Done"

main()

import picostdlib
import picostdlib/pico/sleep

var awake: bool

let led = DefaultLedPin



proc alarmSleepCallback(alarm: HardwareAlarmNum) {.cdecl.} =
  # echo "alarm woke us up"
  # uart_default_tx_wait_blocking();
  awake = true
  alarm.setCallback(nil)
  alarm.unclaim()

proc main() =

  led.init()
  led.setDir(Out)

  #stdio_init_all()
  #echo "Hello Alarm Sleep!"

  while true:
    led.put(High)
    # echo "Awake for 5 seconds"
    sleepMs(1000 * 5)

    #echo "Switching to XOSC"

    # Wait for the fifo to be drained so we get reliable output
    # uart_default_tx_wait_blocking();

    # Set the crystal oscillator as the dormant clock source, UART will be reconfigured from here
    # This is only really necessary before sending the pico dormant but running from xosc while asleep saves power
    led.put(Low)
    sleepRunFromDormantSource(SrcXosc)
    awake = false

    # Go to sleep until the alarm interrupt is generated after 10 seconds
    #echo "Sleeping for 10 seconds"
    #uart_default_tx_wait_blocking();

    led.put(High)

    sleepMs(100)

    if sleepGotoSleepFor(5_000, alarmSleepCallback):
        # Make sure we don't wake
        while not awake:
          #echo "Should be sleeping"
          tightLoopContents()

    # Re-enabling clock sources and generators.
    sleepPowerUp()

main()


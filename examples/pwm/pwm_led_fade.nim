import picostdlib
import picostdlib/hardware/pwm

# Fade an LED between low and high brightness. An interrupt handler updates
# the PWM slice's output level each time the counter wraps.

# Tell the LED pin that the PWM is in charge of its value.
DefaultLedPin.setFunction(Pwm)
# Figure out which slice we just connected to the LED pin
let sliceNum = DefaultLedPin.toPwmSliceNum()

var fade: int = 0
var goingUp: bool = true
proc onPwmWrap() {.cdecl.} =
  # Clear the interrupt flag that brought us here
  sliceNum.clearIrq()

  if goingUp:
    inc(fade)
    if fade > 255:
      fade = 255
      goingUp = false
  else:
    dec(fade)
    if fade < 0:
      fade = 0
      goingUp = true

  # Square the fade value to make the LED's brightness appear more linear
  # Note this range matches with the wrap value
  DefaultLedPin.setPwmLevel(uint16 fade * fade)


# Mask our slice's IRQ output into the PWM block's single interrupt line,
# and register our interrupt handler
sliceNum.clearIrq()
sliceNum.setIrqEnabled(true)
PwmIrqWrap.setExclusiveHandler(onPwmWrap)
PwmIrqWrap.setEnabled(true)

# Get some sensible defaults for the slice configuration. By default, the
# counter is allowed to wrap over its maximum range (0 to 2**16-1)
var config = pwmGetDefaultConfig()
# Set divider, reduces counter clock to sysclock/this value
addr(config).setClkDiv(4.0)
# Load the configuration into our PWM slice, and set it running.
sliceNum.init(config.addr, true)

# Everything after this point happens in the PWM interrupt handler, so we
# can twiddle our thumbs
while true:
  tightLoopContents()

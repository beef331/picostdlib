import picostdlib
import picostdlib/hardware/resets

stdioInitAll()

echo "Hello, reset!"

# Put the PWM block into reset
resetBlockNum(RESET_PWM)

# And bring it out
resetUnresetBlockNumWaitBlocking(RESET_PWM)

# Put the PWM and ADC block into reset
resetBlockMask((1'u32 shl RESET_PWM) or (1'u32 shl RESET_ADC))

# Wait for both to come out of reset
unresetBlockMaskWaitBlocking((1'u32 shl RESET_PWM) or (1'u32 shl RESET_ADC))

echo "ok!"

while true:
  tightLoopContents()


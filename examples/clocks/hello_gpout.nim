import picostdlib
import picostdlib/hardware/clocks

stdioInitAll()

echo "Hello gpout"

# Output clk_sys / 10 to gpio 21, etc...
Gpio(21).initClock(ClocksClkGpoutCtrlAuxSrc.ClkSys, 10)
Gpio(23).initClock(ClocksClkGpoutCtrlAuxSrc.ClkUsb, 10)
Gpio(24).initClock(ClocksClkGpoutCtrlAuxSrc.ClkAdc, 10)
when picoIncludeRtcDatetime:
  Gpio(25).initClock(ClocksClkGpoutCtrlAuxSrc.ClkRtc, 10)

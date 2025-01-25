import std/strformat
import picostdlib
import picostdlib/[hardware/pll, hardware/clocks]

proc measureFreqs() =
  let
    pllSys = frequencyCountKHz(ClocksFc0Src.PllSysClksrcPrimary)
    pllUsb = frequencyCountKHz(ClocksFc0Src.PllUsbClksrcPrimary)
    rosc = frequencyCountKHz(ClocksFc0Src.RoscClksrc)
    clkSys = frequencyCountKHz(ClocksFc0Src.ClkSys)
    clkPeri = frequencyCountKHz(ClocksFc0Src.ClkPeri)
    clkUsb = frequencyCountKHz(ClocksFc0Src.ClkUsb)
    clkAdc = frequencyCountKHz(ClocksFc0Src.ClkAdc)
  when picoIncludeRtcDatetime:
    let clkRtc = frequencyCountKHz(ClocksFc0Src.ClkRtc)

  echo &"pll_sys = {pllSys}kHz"
  echo &"pll_usb = {pllUsb}kHz"
  echo &"rosc = {rosc}kHz"
  echo &"clk_sys = {clkSys}kHz"
  echo &"clk_peri = {clkPeri}kHz"
  echo &"clk_usb = {clkUsb}kHz"
  echo &"clk_adc = {clkAdc}kHz"
  when picoIncludeRtcDatetime:
    echo &"clk_rtc = {clkRtc}kHz"

  # Can't measure clk_ref / xosc as it is the ref

stdioInitAll()

echo "Hello, world!"
measureFreqs()

# Change clk_sys to be 48MHz. The simplest way is to take this from PLL_USB
# which has a source frequency of 48MHz
discard ClockSys.configure(
  1, # CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX
  ClocksClkGpoutCtrlAuxSrc.ClksrcPllUsb.uint32,
  48u32 * MHz,
  48u32 * MHz
)

# Turn off PLL sys for good measure
PllSys.deinit()

# CLK peri is clocked from clk_sys so need to change clk_peri's freq
discard ClockPeri.configure(
  0,
  ClocksClkSysCtrlAuxSrc.ClksrcPllUsb.uint32,
  48 * Mhz,
  48 * Mhz
)

# Re init uart now that clk_peri has changed
stdioInitAll()

echo "Hello, 48MHz"
measureFreqs()

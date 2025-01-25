## From pico-extras repository
##
## Lower Power Sleep API
##
## The difference between sleep and dormant is that ALL clocks are stopped in dormant mode,
## until the source (either xosc or rosc) is started again by an external event.
## In sleep mode some clocks can be left running controlled by the SLEEP_EN registers in the clocks
## block. For example you could keep clk_rtc running. Some destinations (proc0 and proc1 wakeup logic)
## can't be stopped in sleep mode otherwise there wouldn't be enough logic to wake up again.
##
## TODO: Optionally, memories can also be powered down.
##

import std/options

from picostdlib import setupDefaultUart
import ../hardware/[rosc, platform_defs, pll, powman, xosc, sync, structs/scb, timer, regs/cpu]
import ./time, ./aon_timer, ./stdio
import ../helpers
import std/posix
export gpio

type
  DormantSource* = enum
    SrcXosc
    SrcRosc
    SrcLposc # rp2350 only

var dormantSourceCache: Option[DormantSource]
var interruptsCache: uint32

proc sleepRunFromDormantSource*(dormantSource: DormantSource) =
  ## Set all clock sources to the the dormant clock source to prepare for sleep.
  ##
  ## In order to go into dormant mode we need to be running from a stoppable clock source:
  ## either the xosc or rosc with no PLLs running. This means we disable the USB and ADC clocks
  ## and all PLLs
  ##
  ## \param dormant_source The dormant clock source to use

  dormantSourceCache = some(dormantSource)

  var srcHz: uint32
  var clkRefSrc: ClocksClkRefCtrlSrc
  case dormantSource:
  of SrcXosc:
    srcHz = XOSC_HZ
    clkRefSrc = ClocksClkRefCtrlSrc.XoscClksrc
  of SrcRosc:
    srcHz = 6500 * KHz
    clkRefSrc = ClocksClkRefCtrlSrc.RoscClksrcPh
  of SrcLposc:
    when picoRp2350:
      srcHz = 32 * KHz
      clkRefSrc = ClocksClkRefCtrlSrc.LposcClksrc
    else:
      # echo "invalid input"
      return

  #interruptsCache = saveAndDisableInterrupts()
  # #if MICROPY_PY_NETWORK_CYW43
  # if (cyw43_has_pending) {
  #     restore_interrupts(my_interrupts);
  #     return mp_const_none;
  # }
  # #endif

  # CLK_REF = XOSC or ROSC
  discard ClockRef.configure(
    clkRefSrc.uint32,
    0, # No aux mux
    srcHz,
    srcHz
  )

  # CLK_SYS = CLK_REF
  discard ClockSys.configure(
    ClocksClkSysCtrlSrc.ClkRef.uint32,
    0, # Using glitchless mux
    srcHz,
    srcHz
  )

  # CLK ADC = 0MHz
  ClockAdc.stop()
  ClockUsb.stop()
  when picoRp2350:
    ClockHstx.stop()

  when picoRp2040:
    # CLK RTC = ideally XOSC (12MHz) / 256 = 46875Hz but could be rosc
    let clkRtcSrc = if dormantSource == SrcXosc:
      ClocksClkRtcCtrlAuxsrc.XoscClksrc
    else:
      ClocksClkRtcCtrlAuxsrc.RoscClksrcPh

    discard ClockRtc.configure(
      0, # No GLMUX
      clkRtcSrc.uint32,
      srcHz,
      46875
    )

  # CLK PERI = clk_sys. Used as reference clock for Peripherals. No dividers so just select and enable
  discard ClockPeri.configure(
    0,
    ClocksClkPeriCtrlAuxsrc.ClkSys.uint32,
    srcHz,
    srcHz
  )

  PllSys.deinit()
  PllUsb.deinit()

  # Assuming both xosc and rosc are running at the moment
  if dormantSource == SrcXosc:
    # Can disable rosc
    roscDisable()
  else:
    # Can disable xosc
    xoscDisable()

  # Reconfigure uart with new clocks
  setupDefaultUart()

proc processorDeepSleep() =
  when defined(riscv):
    discard
  else:
    scbHw.scr = scbHw.scr or SCR_SLEEPDEEP_BITS

proc sleepRunFromXosc*() {.inline.} =
  ## Set the dormant clock source to be the crystal oscillator
  sleepRunFromDormantSource(SrcXosc)

proc sleepRunFromRosc*() {.inline.} =
  ## Set the dormant clock source to be the ring oscillator
  sleepRunFromDormantSource(SrcRosc)

when picoChip != ChipRp2040:
  proc sleepRunFromLposc*() {.inline.} =
    ## Set the dormant clock source to be LP oscillator
    sleepRunFromDormantSource(SrcLposc)


# proc sleepGotoSleepDelay*(delayMs: uint32) =
#   if dormantSourceCache.isNone: return

#   let sleepEn0 = clocksHw.sleep_en0
#   let sleepEn1 = clocksHw.sleep_en1

#   clocksHw.sleep_en0 = ClocksSleepEn0ClkRtcRtcBits

#   # Use timer
#   clocksHw.sleep_en1 = ClocksSleepEn1ClkSysTimerBits
#   timerHw.alarm[3] = timerHw.timerawl + delayMs * 1000

#   # Enable deep sleep at the proc
#   scbHw.scr = scbHw.scr or M0PLUS_SCR_SLEEPDEEP_BITS

#   # Go to sleep
#   wfi()

#   scbHw.scr = scbHw.scr and (not M0PLUS_SCR_SLEEPDEEP_BITS)
#   clocksHw.sleep_en0 = sleepEn0
#   clocksHw.sleep_en1 = sleepEn1

#   case dormantSourceCache.get():
#   of SrcXosc: roscEnable()
#   of SrcRosc: xoscInit()

#   clocksInit()
#   restoreInterrupts(interruptsCache)
#   interruptsCache.reset()


proc sleepGotoSleepUntil*(ts: ptr Timespec; callback: AonTimerAlarmHandler) =
  ## Send system to sleep until the specified time
  ##
  ## One of the sleep_run_* functions must be called prior to this call
  ##
  ## \param t The time to wake up
  ## \param callback Function to call on wakeup.
  #  We should have already called the sleepRunFromDormantSource function
  # This is only needed for dormancy although it saves power running from xosc while sleeping

  if dormantSourceCache.isNone: return

  # let sleepEn0 = clocksHw.sleep_en0
  # let sleepEn1 = clocksHw.sleep_en1

  when picoRp2040:
    clocksHw.sleep_en0 = ClocksSleepEn0ClkRtcRtcBits
    clocksHw.sleep_en1 = 0x00
  else:
    clocksHw.sleep_en0 = ClocksSleepEn0ClkRefPowmanBits
    clocksHw.sleep_en1 = 0x00

  discard aonTimerEnableAlarm(ts, callback, false)

  stdioFlush()

  # Enable deep sleep at the proc
  processorDeepSleep()

  # Go to sleep
  wfi()

  # scbHw.scr = scbHw.scr and (not M0PLUS_SCR_SLEEPDEEP_BITS)
  # clocksHw.sleep_en0 = sleepEn0
  # clocksHw.sleep_en1 = sleepEn1

  # case dormantSourceCache.get():
  # of SrcXosc: roscEnable()
  # of SrcRosc: xoscInit()

  # clocksInit()
  # restoreInterrupts(interruptsCache)
  # interruptsCache.reset()

proc sleepGotoSleepFor*(delayMs: uint32; callback: HardwareAlarmCallback): bool =
  ## Send system to sleep for a specified duration in milliseconds. This provides an alternative to sleep_goto_sleep_until
  ## to allow for shorter duration sleeps.
  ##
  ## One of the sleep_run_* functions must be called prior to this call
  ##
  ## \param delay_ms The duration to sleep for in milliseconds.
  ## \param callback Function to call on wakeup.
  ## \return Returns true if the device went to sleep
  # We should have already called the sleep_run_from_dormant_source function
  # This is only needed for dormancy although it saves power running from xosc while sleeping

  if dormantSourceCache.isNone: return false

  clocksHw.sleep_en0 = 0x00
  when picoRp2040:
    clocksHw.sleep_en1 = CLOCKS_SLEEP_EN1_CLK_SYS_TIMER_BITS
  else:
    clocksHw.sleep_en1 = CLOCKS_SLEEP_EN1_CLK_REF_TICKS_BITS or CLOCKS_SLEEP_EN1_CLK_SYS_TIMER0_BITS

  let alarm = hardwareAlarmClaimUnused(true).HardwareAlarmNum
  alarm.setCallback(callback)
  let t = makeTimeoutTimeMs(delayMs)
  if alarm.setTarget(t):
    alarm.setCallback(nil)
    alarm.unclaim()
    return false

  stdioFlush()

  # Enable deep sleep at the proc
  processorDeepSleep()

  # Go to sleep
  wfi()

  return true

proc goDormant() =
  if dormantSourceCache.isNone: return
  case dormantSourceCache.get():
  of SrcXosc: xoscDormant()
  of SrcRosc: roscSetDormant()
  else: discard

proc leaveDormant() =
  if dormantSourceCache.isNone: return
  case dormantSourceCache.get():
  of SrcXosc: roscEnable()
  of SrcRosc: xoscInit()
  else: discard
  # clocksInit()

proc sleepGotoDormantUntil*(ts: ptr Timespec; callback: AonTimerAlarmHandler) =
  ## Send system to dormant until the specified time, note for RP2040 the RTC must be driven by an external clock
  ##
  ## One of the sleep_run_* functions must be called prior to this call
  ##
  ## \param ts The time to wake up
  ## \param callback Function to call on wakeup.
  # We should have already called the sleep_run_from_dormant_source function

  if dormantSourceCache.isNone: return

  when picoRp2040:
    clocksHw.sleep_en0 = ClocksSleepEn0ClkRtcRtcBits
    clocksHw.sleep_en1 = 0x00
  else:
    assert(get(dormantSourceCache) == SrcLposc)
    let restoreMs = powmanTimerGetMs()
    powman_timer_set_1khz_tick_source_lposc()
    powman_timer_set_ms(restoreMs)
    clocksHw.sleep_en0 = ClocksSleepEn0ClkRefPowmanBits
    clocksHw.sleep_en1 = 0x00

  discard aonTimerEnableAlarm(ts, callback, false)

  stdioFlush()

  # Enable deep sleep at the proc
  processorDeepSleep()

  # Go dormant
  goDormant()

# proc sleepGotoDormantUntilPin*(gpio: Gpio; eventMask: set[GpioIrqLevel]) =
#   ## Send system to sleep until the specified GPIO changes
#   ##
#   ## One of the sleep_run_* functions must be called prior to this call
#   ##
#   ## \param gpio The pin to provide the wake up
#   ## \param eventMask Which events will cause an interrupt

#   # Configure the appropriate IRQ at IO bank 0
#   # assert(gpio_pin < NUM_BANK0_GPIOS)

#   gpio.setDormantIrqEnabled(eventMask, true)

#   goDormant()
#   # Execution stops here until woken up

#   # Clear the irq so we can go back to dormant mode again if we want
#   gpio.acknowledgeIrq(eventMask)

#   leaveDormant()

# proc sleepGotoDormantUntilEdgeHigh*(gpio: Gpio) {.inline.} =
#   ## Send system to sleep until a leading high edge is detected on GPIO
#   ##
#   ## One of the sleep_run_* functions must be called prior to this call
#   ##
#   ## \param gpio The pin to provide the wake up
#   sleepGotoDormantUntilPin(gpio, {EdgeRise})

# proc sleepGotoDormantUntilLevelHigh*(gpio: Gpio) {.inline.} =
#   ## Send system to sleep until a high level is detected on GPIO
#   ##
#   ## One of the sleep_run_* functions must be called prior to this call
#   ##
#   ## \param gpio The pin to provide the wake up
#   sleepGotoDormantUntilPin(gpio, {LevelHigh})

proc sleepPowerUp*() =
  ## Reconfigure clocks to wake up properly from sleep/dormant mode
  ##
  ## This must be called immediately after continuing execution when waking up from sleep/dormant mode
  # To be called after waking up from sleep/dormant mode to restore system clocks properly

  # Re-enable the ring oscillator, which will essentially kickstart the proc
  roscEnable()

  # Reset the sleep enable register so peripherals and other hardware can be used
  clocksHw.sleep_en0 = clocks_hw.sleep_en0 or not(0.uint32)
  clocksHw.sleep_en1 = clocks_hw.sleep_en0 or not(0.uint32)

  # Restore all clocks
  clocksInit()

  when picoRp2350:
    # make powerman use xosc again
    let restoreMs = powmanTimerGetMs()
    powman_timer_set_1khz_tick_source_xosc()
    powman_timer_set_ms(restoreMs)

  setupDefaultUart()

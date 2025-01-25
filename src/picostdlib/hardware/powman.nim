import ./base, ./gpio
export base, gpio

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_powman/include".}

{.push header: "hardware/powman.h".}

proc powmanTimerSet1khzTickSourceLposc*() {.importc: "powman_timer_set_1khz_tick_source_lposc".}
  ## Use the ~32KHz low power oscillator as the powman timer source

proc powmanTimerSet1khzTickSourceLposcWithHz*(lposcFreqHz: uint32) {.importc: "powman_timer_set_1khz_tick_source_lposc_with_hz".}
  ## Use the low power oscillator (specifying frequency) as the powman timer source
  ##
  ## \param lposc_freq_hz specify an exact lposc freq to trim it

proc powmanTimerSet1khzTickSourceXosc*() {.importc: "powman_timer_set_1khz_tick_source_xosc".}
  ## Use the crystal oscillator as the powman timer source

proc powmanTimerSet1khzTickSourceXoscWithHz*(xoscFreqHz: uint32) {.importc: "powman_timer_set_1khz_tick_source_xosc_with_hz".}
  ## Use the crystal oscillator as the powman timer source
  ##
  ## \param xosc_freq_hz specify a crystal frequency

proc powmanTimerSet1khzTickSourceGpio*(gpio: Gpio) {.importc: "powman_timer_set_1khz_tick_source_gpio".}
  ## Use a 1KHz external tick as the powman timer source
  ##
  ## \param gpio the gpio to use. must be 12, 14, 20, 22

proc powmanTimerEnableGpio1hzSync*(gpio: Gpio) {.importc: "powman_timer_enable_gpio_1hz_sync".}
  ## Use a 1Hz external signal as the powman timer source for seconds only
  ##
  ## Use a 1hz sync signal, such as from a gps for the seconds component of the timer.
  ## The milliseconds will still come from another configured source such as xosc or lposc
  ##
  ## \param gpio the gpio to use. must be 12, 14, 20, 22

proc powmanTimerDisableGpio1hzSync*() {.importc: "powman_timer_disable_gpio_1hz_sync".}
  ## Stop using 1Hz external signal as the powman timer source for seconds

proc powmanTimerGetMs*(): uint64 {.importc: "powman_timer_get_ms".}
  ## Returns current time in ms

proc powmanTimerSetMs*(timeMs: uint64) {.importc: "powman_timer_set_ms".}
  ## Set current time in ms
  ##
  ## \param time_ms Current time in ms

proc powmanTimerEnableAlarmAtMs*(alarmTimeMs: uint64) {.importc: "powman_timer_enable_alarm_at_ms".}
  ## Set an alarm at an absolute time in ms
  ##
  ## Note, the timer is stopped and then restarted as part of this function. This only controls the alarm
  ## if you want to use the alarm to wake up powman then you should use \ref powman_enable_alarm_wakeup_at_ms
  ##
  ## \param alarm_time_ms time at which the alarm will fire

proc powmanTimerDisableAlarm*() {.importc: "powman_timer_disable_alarm".}
  ## Disable the alarm
  ##
  ## Once an alarm has fired it must be disabled to stop firing as the alarm
  ## comparison is alarm = alarm_time >= current_time

proc powmanSetBits*(reg: ptr uint32, bits: uint32) {.importc: "powman_set_bits".}
  ## hw_set_bits helper function
  ##
  ## \param reg register to set
  ## \param bits bits of register to set
  ## Powman needs a password for writes, to prevent accidentally writing to it.
  ## This function implements hw_set_bits with an appropriate password.

proc powmanClearBits*(reg: ptr uint32, bits: uint32) {.importc: "powman_clear_bits".}
  ## hw_clear_bits helper function
  ##
  ## Powman needs a password for writes, to prevent accidentally writing to it.
  ## This function implements hw_clear_bits with an appropriate password.
  ##
  ## \param reg register to clear
  ## \param bits bits of register to clear

proc powmanTimerIsRunning*(): bool {.importc: "powman_timer_is_running".}
  ## Determine if the powman timer is running

proc powmanTimerStop*() {.importc: "powman_timer_stop".}
  ## Stop the powman timer

proc powmanTimerStart*() {.importc: "powman_timer_start".}
  ## Start the powman timer

proc powmanClearAlarm*() {.importc: "powman_clear_alarm".}
  ## Clears the powman alarm
  ##
  ## Note, the alarm must be disabled (see \ref powman_timer_disable_alarm) before clearing the alarm, as the alarm fires if
  ## the time is greater than equal to the target, so once the time has passed the alarm will always fire while enabled.

type
  PowmanPowerDomains* {.importc: "enum powman_power_domains".} = enum
    ## Power domains of powman
    POWMAN_POWER_DOMAIN_SRAM_BANK1 = 0    # bank1 includes the top 256K of sram plus sram 8 and 9 (scratch x and scratch y)
    POWMAN_POWER_DOMAIN_SRAM_BANK0 = 1    # bank0 is bottom 256K of sSRAM
    POWMAN_POWER_DOMAIN_XIP_CACHE = 2     # XIP cache is 2x8K instances
    POWMAN_POWER_DOMAIN_SWITCHED_CORE = 3 # Switched core logic (processors, busfabric, peris etc)
    POWMAN_POWER_DOMAIN_COUNT = 4
  
  PowmanPowerState* = uint32

let POWMAN_POWER_STATE_NONE* {.importc: "POWMAN_POWER_STATE_NONE".}: PowmanPowerState

proc powmanGetPowerState*(): PowmanPowerState {.importc: "powman_get_power_state".}
  ## Get the current power state

proc powmanSetPowerState*(state: PowmanPowerState): cint {.importc: "".}
  ## Set the power state
  ##
  ## Check the desired state is valid. Powman will go to the state if it is valid and there are no pending power up requests.
  ##
  ## Note that if you are turning off the switched core then this function will never return as the processor will have
  ## been turned off at the end.
  ##
  ## \param state the power state to go to
  ## \returns PICO_OK if the state is valid. Misc PICO_ERRORs are returned if not

proc powmanPowerStateWithDomainOn*(orig: PowmanPowerState; domain: PowmanPowerDomains): PowmanPowerState {.importc: "powman_power_state_with_domain_on".}
  ## Helper function modify a powman_power_state to turn a domain on
  ##
  ## \param orig original state
  ## \param domain domain to turn on

proc powmanPowerStateWithDomainOff*(orig: PowmanPowerState; domain: PowmanPowerDomains): PowmanPowerState {.importc: "powman_power_state_with_domain_off".}
  ## Helper function modify a powman_power_state to turn a domain off
  ##
  ## \param orig original state
  ## \param domain domain to turn off

proc powmanPowerStateIsDomainOn*(state: PowmanPowerState; domain: PowmanPowerDomains): bool {.importc: "powman_power_state_is_domain_on".}
  ## Helper function to check if a domain is on in a given powman_power_state
  ##
  ## \param state powman_power_state
  ## \param domain domain to check is on

proc powmanEnableAlarmWakeupAtMs*(alarmTimeMs: uint64) {.importc: "powman_enable_alarm_wakeup_at_ms".}
  ## Wake up from an alarm at a given time
  ##
  ## \param alarm_time_ms time to wake up in ms

proc powmanEnableGpioWakeup*(gpioWakeupNum: cuint; gpio: Gpio; edge: bool; activeHigh: bool) {.importc: "powman_enable_gpio_wakeup".}
  ## Wake up from a gpio
  ##
  ## \param gpio_wakeup_num hardware wakeup instance to use (0-3)
  ## \param gpio gpio to wake up from (0-47)
  ## \param edge true for edge sensitive, false for level sensitive
  ## \param high true for active high, false active low

proc powmanDisableAlarmWakeup*() {.importc: "powman_disable_alarm_wakeup".}
  ## Disable waking up from alarm

proc powmanDisableGpioWakeup*(gpioWakeupNum: cuint) {.importc: "powman_disable_gpio_wakeup".}
  ## Disable wake up from a gpio
  ##
  ## \param gpio_wakeup_num hardware wakeup instance to use (0-3)

proc powmanDisableAllWakeups*() {.importc: "powman_disable_all_wakeups".}
  ## Disable all wakeup sources

proc powmanConfigureWakeupState*(sleepState: PowmanPowerState; wakeupState: PowmanPowerState): bool {.importc: "powman_configure_wakeup_state".}
  ## Configure sleep state and wakeup state
  ##
  ## \param sleep_state power state powman will go to when sleeping, used to validate the wakeup state
  ## \param wakeup_state power state powman will go to when waking up. Note switched core and xip always power up. SRAM bank0 and bank1 can be left powered off
  ## \returns true if the state is valid, false if not

proc powmanSetDebugPowerRequestIgnored*(ignored: bool) {.importc: "powman_set_debug_power_request_ignored".}
  ## Ignore wake up when the debugger is attached
  ##
  ## Typically, when a debugger is attached it will assert the pwrupreq signal. OpenOCD does not clear this signal, even when you quit.
  ## This means once you have attached a debugger powman will never go to sleep. This function lets you ignore the debugger
  ## pwrupreq which means you can go to sleep with a debugger attached. The debugger will error out if you go to turn off the switch core with it attached,
  ## as the processors have been powered off.
  ##
  ## \param ignored should the debugger power up request be ignored

{.pop.}

import ./platform_defs, ./base, ../pico/types
export base, types

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_timer/include".}
{.push header: "hardware/timer.h".}

type
  TimerHw* {.importc: "timer_hw_t".} = object
    # incomplete
    alarm*: array[NUM_TIMERS, IoRw32]
    timerawh*: IoRo32
    timerawl*: IoRo32

let timerHw* {.importc: "timer_hw".}: ptr TimerHw

type
  HardwareAlarmNum* = distinct cuint

  HardwareAlarmCallback* {.importc: "hardware_alarm_callback_t".} = proc (alarmNum: HardwareAlarmNum) {.cdecl.}

proc `==`*(a, b: HardwareAlarmNum): bool {.borrow.}
proc `$`*(a: HardwareAlarmNum): string {.borrow.}

proc timeUs32*(): uint32 {.importc: "time_us_32".}
  ## Return a 32 bit timestamp value in microseconds
  ##
  ## Returns the low 32 bits of the hardware timer.
  ## \note This value wraps roughly every 1 hour 11 minutes and 35 seconds.
  ##
  ## \return the 32 bit timestamp

proc timeUs64*(): uint64 {.importc: "time_us_64".}
  ## Return the current 64 bit timestamp value in microseconds
  ##
  ## Returns the full 64 bits of the hardware timer. The \ref pico_time and other functions rely on the fact that this
  ## value monotonically increases from power up. As such it is expected that this value counts upwards and never wraps
  ## (we apologize for introducing a potential year 5851444 bug).
  ##
  ## \return the 64 bit timestamp

proc busyWaitUs32*(delayUs: uint32) {.importc: "busy_wait_us_32".}
  ## Busy wait wasting cycles for the given (32 bit) number of microseconds
  ##
  ## \param delay_us delay amount in microseconds

proc busyWaitUs*(delayUs: uint64) {.importc: "busy_wait_us".}
  ## Busy wait wasting cycles for the given (64 bit) number of microseconds
  ##
  ## \param delay_us delay amount in microseconds

proc busyWaitMs*(delayMs: uint32) {.importc: "busy_wait_ms".}
  ## Busy wait wasting cycles for the given number of milliseconds
  ##
  ## \param delay_ms delay amount in milliseconds

proc busyWaitUntil*(t: AbsoluteTime) {.importc: "busy_wait_until".}
  ## Busy wait wasting cycles until after the specified timestamp
  ##
  ## \param t Absolute time to wait until

proc timeReached*(t: AbsoluteTime): bool {.importc: "time_reached".}
  ## Check if the specified timestamp has been reached
  ##
  ## \param t Absolute time to compare against current time
  ## \return true if it is now after the specified timestamp

proc claim*(alarmNum: HardwareAlarmNum) {.importc: "hardware_alarm_claim".}
  ## cooperatively claim the use of this hardware alarm_num
  ##
  ## This method hard asserts if the hardware alarm is currently claimed.
  ##
  ## \param alarm_num the hardware alarm to claim
  ## \sa hardware_claiming

proc hardwareAlarmClaimUnused*(required: bool): cint {.importc: "hardware_alarm_claim_unused".}
  ## Cooperatively claim the use of this hardware alarm_num
  ##
  ## This method attempts to claim an unused hardware alarm
  ##
  ## \return alarm_num the hardware alarm claimed or -1 if required was false, and none are available
  ## \sa hardware_claiming

proc unclaim*(alarmNum: HardwareAlarmNum) {.importc: "hardware_alarm_unclaim".}
  ## cooperatively release the claim on use of this hardware alarm_num
  ##
  ## \param alarm_num the hardware alarm to unclaim
  ## \sa hardware_claiming

proc isClaimed*(alarmNum: HardwareAlarmNum): bool {.importc: "hardware_alarm_is_claimed".}
  ## Determine if a hardware alarm has been claimed
  ##
  ## \param alarm_num the hardware alarm number
  ## \return true if claimed, false otherwise
  ## \see hardware_alarm_claim

proc setCallback*(alarmNum: HardwareAlarmNum; callback: HardwareAlarmCallback) {.importc: "hardware_alarm_set_callback".}
  ## Enable/Disable a callback for a hardware timer on this core
  ##
  ## This method enables/disables the alarm IRQ for the specified hardware alarm on the
  ## calling core, and set the specified callback to be associated with that alarm.
  ##
  ## This callback will be used for the timeout set via hardware_alarm_set_target
  ##
  ## \note This will install the handler on the current core if the IRQ handler isn't already set.
  ## Therefore the user has the opportunity to call this up from the core of their choice
  ##
  ## \param alarm_num the hardware alarm number
  ## \param callback the callback to install, or NULL to unset
  ##
  ## \sa hardware_alarm_set_target()

proc setTarget*(alarmNum: HardwareAlarmNum; t: AbsoluteTime): bool {.importc: "hardware_alarm_set_target".}
  ## Set the current target for the specified hardware alarm
  ##
  ## This will replace any existing target
  ##
  ## @param alarm_num the hardware alarm number
  ## @param t the target timestamp
  ## @return true if the target was "missed"; i.e. it was in the past, or occurred before a future hardware timeout could be set

proc cancel*(alarmNum: HardwareAlarmNum) {.importc: "hardware_alarm_cancel".}
  ## Cancel an existing target (if any) for a given hardware_alarm
  ##
  ## @param alarm_num the hardware alarm number

proc forceIrq*(alarmNum: HardwareAlarmNum) {.importc: "hardware_alarm_force_irq".}
  ## Force and IRQ for a specific hardware alarm
  ##
  ## This method will forcibly make sure the current alarm callback (if present) for the hardware
  ## alarm is called from an IRQ context after this call. If an actual callback is due at the same
  ## time then the callback may only be called once.
  ##
  ## Calling this method does not otherwise interfere with regular callback operations.
  ##
  ## @param alarm_num the hardware alarm number

{.pop.}

# Nim helpers


# For FreeRTOS/Posix support

# when defined(freertos):
#   import std/posix

#   proc clock_gettime(clkId: ClockId; tp: var Timespec): cint {.exportc: "clock_gettime".} =
#     let m = timeUs64()
#     tp.tv_sec = Time(m div 1000000)
#     tp.tv_nsec = clong((m mod 1000000) * 1000)
#     return 0
